defmodule Servidor do
  
  #FUNCIONES PUBLICAS
  @spec start(integer()) :: {:ok, pid()}
  def start(n) do
    {:ok, spawn(fn -> init(n) end)}
  end
  
  @spec run_batch(pid(), list()) :: list()
  def run_batch(master, jobs) do
    ref = make_ref()
    send(master, {:trabajos, self(), ref, jobs})
    
    receive do
      {:respuesta, ^ref, resultados} -> resultados
    end
  end
  
  @spec stop(pid()) :: :ok
  def stop(master) do
    send(master, {:stop, self()})
    
    receive do
      {:ok, ^master} -> :ok
    end
  end

  #FUNCIONES PRIVADAS
  
  defp init(n) do
    workers = for _ <- 1..n, do: Trabajador.start()
    loop(workers, nil, nil, %{}, 0)
  end

  #MUY SENCILLO:
  #SI RECIBE TRABAJOS Y EL LOTE NO ES MAS GRANDE QUE EL POOL, ASIGNA LOS TRABAJOS
  #SI EL LOTE ES MAS GRANDE, RESPONDE CON ERROR
  #SI RECIBE RESULTADOS, LOS ALMACENA Y SI SON TODOS, RESPONDE AL CLIENTE
  #SI RECIBE STOP, PARA A TODOS LOS TRABAJADORES
  
  defp loop(workers, client, batchRef, results, pending) do
    receive do
      
      {:trabajos, from, ref, jobs} ->
        if length(jobs) > length(workers) do
          send(from, {:respuesta, ref, {:error, :lote_demasiado_grande}})
          loop(workers, client, batchRef, results, pending)
        else
          Enum.with_index(jobs)
          |> Enum.each(fn {job, idx} ->
            worker = Enum.at(workers, idx)
            send(worker, {:trabajo, self(), fn -> {idx, job.()} end})
          end)
          
          loop(workers, from, ref, %{}, length(jobs))
        end

      {:resultado, _worker, {idx, result}} ->
        newResults = Map.put(results, idx, result)
        newPending = pending - 1
        
        if newPending == 0 do
          orderedResults = for i <- 0..(map_size(newResults)-1), do: newResults[i]
          send(client, {:respuesta, batchRef, orderedResults}) 
          loop(workers, nil, nil, %{}, 0)
        else
          loop(workers, client, batchRef, newResults, newPending)
        end

      {:stop, from} ->
        Enum.each(workers, fn worker -> send(worker, :stop) end)
        send(from, {:ok, self()})
        
    end
  end
end