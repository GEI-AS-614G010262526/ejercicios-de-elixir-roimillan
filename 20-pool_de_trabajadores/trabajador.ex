defmodule Trabajador do
  
  def start() do
    spawn(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:trabajo, from, func} ->
        result = safe_execute(func)
        send(from, {:resultado, self(), result})
        loop()

      :stop ->
        :ok

      _other ->
        loop()
    end
  end

  defp safe_execute(func) do
    try do
      {:ok, func.()}
    rescue
      exception -> {:error, exception}
    catch
      kind, reason -> {:error, {kind, reason}}
    end
  end
end