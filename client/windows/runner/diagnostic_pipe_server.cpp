#include "diagnostic_pipe_server.h"

#include <vector>

namespace {
constexpr wchar_t kPipeName[] = L"\\\\.\\pipe\\HiHat.Diagnostics";
}

DiagnosticPipeServer::DiagnosticPipeServer(HWND window) : window_(window) {}
DiagnosticPipeServer::~DiagnosticPipeServer() { Stop(); }

void DiagnosticPipeServer::Start() { thread_ = std::thread(&DiagnosticPipeServer::Run, this); }

void DiagnosticPipeServer::Stop() {
  stopping_ = true;
  HANDLE wake = CreateFileW(kPipeName, GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                            OPEN_EXISTING, 0, nullptr);
  if (wake != INVALID_HANDLE_VALUE) CloseHandle(wake);
  if (thread_.joinable()) thread_.join();
}

void DiagnosticPipeServer::Run() {
  while (!stopping_) {
    HANDLE pipe = CreateNamedPipeW(
        kPipeName, PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS,
        1, 64 * 1024, 64 * 1024, 0, nullptr);
    if (pipe == INVALID_HANDLE_VALUE) return;
    const BOOL connected = ConnectNamedPipe(pipe, nullptr) || GetLastError() == ERROR_PIPE_CONNECTED;
    if (!connected || stopping_) {
      CloseHandle(pipe);
      continue;
    }

    std::vector<char> buffer(64 * 1024);
    DWORD read = 0;
    if (ReadFile(pipe, buffer.data(), static_cast<DWORD>(buffer.size() - 1), &read, nullptr) && read > 0) {
      auto* request = new DiagnosticPipeRequest();
      request->request.assign(buffer.data(), read);
      while (!request->request.empty() &&
             (request->request.back() == '\n' || request->request.back() == '\r')) {
        request->request.pop_back();
      }
      request->completed = CreateEventW(nullptr, TRUE, FALSE, nullptr);
      if (request->completed && PostMessageW(window_, kDiagnosticPipeMessage, 0,
                                             reinterpret_cast<LPARAM>(request))) {
        if (WaitForSingleObject(request->completed, 30000) != WAIT_OBJECT_0) {
          request->response = R"({"ok":false,"error":"DIAGNOSTIC_TIMEOUT"})";
        }
        DWORD written = 0;
        request->response.push_back('\n');
        WriteFile(pipe, request->response.data(),
                  static_cast<DWORD>(request->response.size()), &written, nullptr);
      }
      if (request->completed) CloseHandle(request->completed);
      delete request;
    }
    FlushFileBuffers(pipe);
    DisconnectNamedPipe(pipe);
    CloseHandle(pipe);
  }
}
