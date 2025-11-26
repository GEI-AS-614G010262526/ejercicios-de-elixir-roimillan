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
    loop(workers, workers, nil, nil, %{}, 0)
  end

  #MUY SENCILLO:
  #SI RECIBE TRABAJOS Y HAY SUFICIENTES TRABAJADORES LIBRES, ASIGNA LOS TRABAJOS
  #SI NO HAY SUFICIENTES, RESPONDE CON ERROR
  #SI RECIBE RESULTADOS, LOS ALMACENA Y SI SON TODOS, RESPONDE AL CLIENTE
  #SI RECIBE STOP, PARA A TODOS LOS TRABAJADORES
  
  defp loop(workers, free_workers, client, batch_ref, results, pending) do
    receive do
      {:trabajos, from, ref, jobs} ->
        if length(jobs) > length(workers) do
          send(from, {:respuesta, ref, {:error, :lote_demasiado_grande}})
          loop(workers, free_workers, client, batch_ref, results, pending)
        else
          {assigned, remaining_free} = Enum.split(free_workers, length(jobs))
          
          Enum.with_index(jobs)
          |> Enum.each(fn {job, idx} ->
            worker = Enum.at(assigned, idx)
            send(worker, {:trabajo, self(), fn -> {idx, job.()} end})
          end)
          
          loop(workers, remaining_free, from, ref, %{}, length(jobs))
        end

      {:resultado, worker, {idx, result}} ->
        new_results = Map.put(results, idx, result)
        new_free = [worker | free_workers]
        new_pending = pending - 1
        
        if new_pending == 0 do
          ordered_results = for i <- 0..(map_size(new_results)-1), do: new_results[i]
          send(client, {:respuesta, batch_ref, ordered_results}) 
          loop(workers, new_free, nil, nil, %{}, 0)
        else
          loop(workers, new_free, client, batch_ref, new_results, new_pending)
        end

      {:stop, from} ->
        Enum.each(workers, fn worker -> send(worker, :stop) end)
        send(from, {:ok, self()})
    end
  end
end