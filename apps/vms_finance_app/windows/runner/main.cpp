#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <sddl.h>
#include <windows.h>

#include <string>
#include <thread>
#include <vector>

#include "../flutter/ephemeral/.plugin_symlinks/auth0_flutter/windows/plugin_startup_url_lock.h"
#include "flutter_window.h"
#include "utils.h"

const wchar_t* kSingleInstanceMutex = L"vmsfinance_auth_single_instance";
const wchar_t* kRedirectPipeName = L"\\\\.\\pipe\\vmsfinance_auth_callback";

std::wstring ReadCallbackPrefix() {
  return VMS_AUTH0_WINDOWS_CALLBACK_URL;
}

bool IsExpectedCallback(const std::wstring& uri) {
  const std::wstring prefix = ReadCallbackPrefix();
  return !prefix.empty() && uri.rfind(prefix, 0) == 0;
}

PSECURITY_DESCRIPTOR BuildCurrentUserSecurityDescriptor() {
  HANDLE token = nullptr;
  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return nullptr;
  DWORD size = 0;
  GetTokenInformation(token, TokenUser, nullptr, 0, &size);
  if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    CloseHandle(token);
    return nullptr;
  }
  std::vector<BYTE> buffer(size);
  auto* token_user = reinterpret_cast<PTOKEN_USER>(buffer.data());
  if (!GetTokenInformation(token, TokenUser, token_user, size, &size)) {
    CloseHandle(token);
    return nullptr;
  }
  CloseHandle(token);
  LPWSTR sid = nullptr;
  if (!ConvertSidToStringSidW(token_user->User.Sid, &sid)) return nullptr;
  std::wstring sddl = L"D:(A;;GRGW;;;";
  sddl += sid;
  sddl += L")";
  LocalFree(sid);
  PSECURITY_DESCRIPTOR descriptor = nullptr;
  ConvertStringSecurityDescriptorToSecurityDescriptorW(
      sddl.c_str(), SDDL_REVISION_1, &descriptor, nullptr);
  return descriptor;
}

void BringExistingWindowToFront() {
  HWND window = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
  if (window) {
    ShowWindow(window, SW_RESTORE);
    SetForegroundWindow(window);
  }
}

void ForwardToFirstInstance(const wchar_t* uri) {
  if (!WaitNamedPipeW(kRedirectPipeName, 2000)) return;
  HANDLE pipe = CreateFileW(kRedirectPipeName, GENERIC_WRITE, 0, nullptr,
                            OPEN_EXISTING, 0, nullptr);
  if (pipe == INVALID_HANDLE_VALUE && GetLastError() == ERROR_PIPE_BUSY &&
      WaitNamedPipeW(kRedirectPipeName, 2000)) {
    pipe = CreateFileW(kRedirectPipeName, GENERIC_WRITE, 0, nullptr,
                       OPEN_EXISTING, 0, nullptr);
  }
  if (pipe == INVALID_HANDLE_VALUE) return;
  const DWORD length = static_cast<DWORD>((wcslen(uri) + 1) * sizeof(wchar_t));
  DWORD written = 0;
  WriteFile(pipe, uri, length, &written, nullptr);
  CloseHandle(pipe);
}

void StartPipeServer() {
  std::thread([] {
    while (true) {
      PSECURITY_DESCRIPTOR descriptor = BuildCurrentUserSecurityDescriptor();
      if (!descriptor) return;
      SECURITY_ATTRIBUTES attributes = {};
      attributes.nLength = sizeof(attributes);
      attributes.lpSecurityDescriptor = descriptor;
      attributes.bInheritHandle = FALSE;
      HANDLE pipe = CreateNamedPipeW(
          kRedirectPipeName, PIPE_ACCESS_INBOUND | FILE_FLAG_FIRST_PIPE_INSTANCE,
          PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT, 1, 0, 0, 0,
          &attributes);
      LocalFree(descriptor);
      if (pipe == INVALID_HANDLE_VALUE) return;
      const BOOL connected = ConnectNamedPipe(pipe, nullptr);
      if (connected || GetLastError() == ERROR_PIPE_CONNECTED) {
        wchar_t buffer[2048];
        DWORD bytes_read = 0;
        const BOOL read_ok = ReadFile(
            pipe, buffer, sizeof(buffer) - sizeof(wchar_t), &bytes_read, nullptr);
        if (read_ok) {
          buffer[bytes_read / sizeof(wchar_t)] = L'\0';
          const std::wstring uri(buffer);
          if (IsExpectedCallback(uri)) {
            auth0_flutter::WriteLockGuard lock(auth0_flutter::GetPluginUrlRwLock());
            if (lock.IsValid()) {
              SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", uri.c_str());
            }
            BringExistingWindowToFront();
          }
        }
      }
      DisconnectNamedPipe(pipe);
      CloseHandle(pipe);
    }
  }).detach();
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  int argument_count = 0;
  LPWSTR* arguments = CommandLineToArgvW(GetCommandLineW(), &argument_count);
  std::wstring startup_uri;
  if (arguments && argument_count > 1) startup_uri = arguments[1];
  if (arguments) LocalFree(arguments);

  HANDLE mutex = CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  const bool already_running = mutex && GetLastError() == ERROR_ALREADY_EXISTS;
  if (already_running) {
    BringExistingWindowToFront();
    if (IsExpectedCallback(startup_uri)) ForwardToFirstInstance(startup_uri.c_str());
    CloseHandle(mutex);
    return 0;
  }
  SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL",
                          IsExpectedCallback(startup_uri) ? startup_uri.c_str() : L"");
  StartPipeServer();

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(GetCommandLineArguments());
  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"VMS Finance", origin, size)) return EXIT_FAILURE;
  window.SetQuitOnClose(true);
  ::MSG message;
  while (::GetMessage(&message, nullptr, 0, 0)) {
    ::TranslateMessage(&message);
    ::DispatchMessage(&message);
  }
  if (mutex) CloseHandle(mutex);
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
