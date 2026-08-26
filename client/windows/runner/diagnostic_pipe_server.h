#ifndef RUNNER_DIAGNOSTIC_PIPE_SERVER_H_
#define RUNNER_DIAGNOSTIC_PIPE_SERVER_H_

#include <windows.h>

#include <atomic>
#include <string>
#include <thread>

constexpr UINT kDiagnosticPipeMessage = WM_APP + 42;

struct DiagnosticPipeRequest {
  std::string request;
  std::string response;
  HANDLE completed = nullptr;
};

class DiagnosticPipeServer {
 public:
  explicit DiagnosticPipeServer(HWND window);
  ~DiagnosticPipeServer();
  void Start();
  void Stop();

 private:
  void Run();
  HWND window_;
  std::atomic<bool> stopping_{false};
  std::thread thread_;
};

#endif
