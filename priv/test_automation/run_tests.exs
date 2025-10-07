#!/usr/bin/env elixir

# Automated Test Runner and Reporter
# Usage: mix run priv/test_automation/run_tests.exs

Mix.install([
  {:jason, "~> 1.4"}
])

defmodule TestAutomation do
  @moduledoc """
  Automated test runner with comprehensive reporting
  """

  def run do
    IO.puts("\n#{String.duplicate("=", 80)}")
    IO.puts("SHOP1 CMMS - Automated Test Suite")
    IO.puts(String.duplicate("=", 80)}")
    IO.puts("Started at: #{DateTime.utc_now() |> DateTime.to_string()}\n")

    results = %{
      unit_tests: run_unit_tests(),
      context_tests: run_context_tests(),
      liveview_tests: run_liveview_tests(),
      integration_tests: run_integration_tests()
    }

    generate_report(results)
    
    # Return exit code based on results
    if all_passed?(results) do
      IO.puts("\n✅ ALL TESTS PASSED")
      System.halt(0)
    else
      IO.puts("\n❌ SOME TESTS FAILED")
      System.halt(1)
    end
  end

  defp run_unit_tests do
    IO.puts("\n📦 Running Unit Tests...")
    IO.puts(String.duplicate("-", 80))
    
    result = System.cmd("mix", ["test", "test/shop1_cmms", "--trace"], 
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )
    
    parse_test_result(result)
  end

  defp run_context_tests do
    IO.puts("\n🔧 Running Context Tests...")
    IO.puts(String.duplicate("-", 80))
    
    result = System.cmd("mix", ["test", "test/shop1_cmms", 
      "--only", "context",
      "--trace"
    ], 
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )
    
    parse_test_result(result)
  end

  defp run_liveview_tests do
    IO.puts("\n🖥️  Running LiveView Tests...")
    IO.puts(String.duplicate("-", 80))
    
    result = System.cmd("mix", ["test", "test/shop1_cmms_web/live", "--trace"], 
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )
    
    parse_test_result(result)
  end

  defp run_integration_tests do
    IO.puts("\n🔗 Running Integration Tests...")
    IO.puts(String.duplicate("-", 80))
    
    # Check if integration tests exist
    if File.exists?("test/shop1_cmms_web/integration") do
      result = System.cmd("mix", ["test", "test/shop1_cmms_web/integration", "--trace"], 
        stderr_to_stdout: true,
        into: IO.stream(:stdio, :line)
      )
      
      parse_test_result(result)
    else
      IO.puts("⚠️  No integration tests found (directory doesn't exist)")
      %{passed: 0, failed: 0, skipped: 0, total: 0, duration: 0, status: :not_found}
    end
  end

  defp parse_test_result({output, exit_code}) do
    # Parse test output for statistics
    # This is a simple parser - could be enhanced
    %{
      status: if(exit_code == 0, do: :passed, else: :failed),
      exit_code: exit_code,
      output: output
    }
  end

  defp generate_report(results) do
    IO.puts("\n#{String.duplicate("=", 80)}")
    IO.puts("TEST RESULTS SUMMARY")
    IO.puts(String.duplicate("=", 80)}")

    Enum.each(results, fn {suite, result} ->
      status_icon = if result.status == :passed, do: "✅", else: "❌"
      IO.puts("#{status_icon} #{format_suite_name(suite)}: #{result.status}")
    end)

    IO.puts("\nCompleted at: #{DateTime.utc_now() |> DateTime.to_string()}")
    IO.puts(String.duplicate("=", 80))

    # Generate JSON report
    generate_json_report(results)
  end

  defp generate_json_report(results) do
    report = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      results: results,
      summary: %{
        total_suites: map_size(results),
        passed_suites: Enum.count(results, fn {_, r} -> r.status == :passed end),
        failed_suites: Enum.count(results, fn {_, r} -> r.status == :failed end)
      }
    }

    File.mkdir_p!("priv/test_automation/reports")
    
    filename = "priv/test_automation/reports/test_report_#{DateTime.utc_now() |> DateTime.to_unix()}.json"
    File.write!(filename, Jason.encode!(report, pretty: true))
    
    IO.puts("\n📄 JSON report saved to: #{filename}")
  end

  defp all_passed?(results) do
    Enum.all?(results, fn {_, result} -> 
      result.status in [:passed, :not_found]
    end)
  end

  defp format_suite_name(:unit_tests), do: "Unit Tests"
  defp format_suite_name(:context_tests), do: "Context Tests"
  defp format_suite_name(:liveview_tests), do: "LiveView Tests"
  defp format_suite_name(:integration_tests), do: "Integration Tests"
end

# Run the test automation
TestAutomation.run()
