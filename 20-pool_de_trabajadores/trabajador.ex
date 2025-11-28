defmodule Trabajador do
  def start() do
    spawn(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:trabajo, from, func} ->
        # func es: fn -> {idx, job.()} end
        {idx, result} = safe_execute(func)  # ← EXTRAEMOS índice y resultado
        send(from, {:resultado, self(), {idx, result}})
        loop()

      :stop ->
        :ok

      _other ->
        loop()
    end
  end

  defp safe_execute(func) do
    try do
      func.()  # ← Devuelve directo {idx, resultado}
    rescue
      exception -> {:error, exception}
    catch
      kind, reason -> {:error, {kind, reason}}
    end
  end
end