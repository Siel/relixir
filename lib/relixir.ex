defmodule Relixir do

  @moduledoc """
  This package provides a wrapper around the `r` command line `littler` which provides the same functionality as `Rscript`, but a little faster.
  You need to have `littler` on your system in order to use this module.

  You can install `littler` from CRAN
  ```R
  install.packages('littler')
  ```
  """

  @doc """
  Execute a chunk of `rCode` via little r command, returning the `export` variable in the `output format.
  2 types of outputs are supported, `R` and `json`. Both are treated as binary in Elixir.
  """
  def runR(rCode, export \\ "", opts \\ %{"output" => "R"})
  def runR(rCode, export, _ ) when (is_binary(rCode) and (export == "")) do
    script = """
    tmpVar <- sprintf("tmp%03s", sample(1:100,1))
    assign(tmpVar, {#{rCode}})
    cat(serialize(connection=stdout(), object=get(tmpVar)))
    """
    openRPort(script)
  end

  def runR(rCode, export, %{"output" => output}) when (is_binary(rCode) and is_binary(export)) do
    exportCmd = if (output == "json"), do: "jsonlite::toJSON(#{export}, force=TRUE)", else: "serialize(connection=stdout(), object=#{export})"
    script = """
    #{rCode}
    cat(#{exportCmd})
    """
    openRPort(script)
  end

  defp openRPort(script) do
    port = Port.open({:spawn_executable, littlerExec()},
                     [{:args, ["-e",script]},
                     :stream, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout])
    data = receive do
      {^port, {:data, data}} -> data
    end

    receive do
      {^port, {:exit_status, status}}  when status > 0 ->
        {:error, data}
      {^port, {:exit_status, status}}  when status == 0 ->
        data
    end
  end
  # TODO
  # def callRFunc(rCode, args) when is_binary(rCode) do
  #   port = Port.open({:spawn_executable, littlerExec()},
  #                    [{:args, ["-e", "cat(serialize(connection=stdout(), object=" <> rCode <> "))"]},
  #                    :stream, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout])
  #   return_data(port)
  # end

  defp littlerExec() do
    String.replace( System.find_executable("R"), "/bin/R", "/library/littler/bin/r")
  end
  # defp rscriptExec() do
  #   System.find_executable("R")
  # end
  # def script(scriptFile, args) when is_list(args) do
  #   port = Port.open({:spawn_executable, rscriptExec()}, [{:args, [scriptFile] ++ args}, :stream, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout])
  #   handle_output(port)
  # end

  # def handle_output(port) do
  #   receive do
  #     {^port, {:data, data}} ->
  #       IO.puts(data)
  #       handle_output(port)
  #     {^port, {:exit_status, status}} ->
  #       {:exit_status, status}
  #   end
  # end


  # ## Return data received at the given port if exec was successful, error message otherwise
  # defp return_data(port) do
  #   receive do
  #     {^port, {:data, data}} ->
  #       data
  #     {^port, {:exit_status, status}}  when status != 0 ->
  #       send port, {self(), {:exit_status, 0}}
  #       :error
  #     {^port, {:exit_status, status}}  when status == 0 ->
  #       send port, {self(), :close}
  #   end
  # end
end
