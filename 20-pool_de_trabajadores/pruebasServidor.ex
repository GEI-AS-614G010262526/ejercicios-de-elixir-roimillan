defmodule PruebasServidor do
  def ejecutarTodas do
    IO.puts("=== Pruebas servidor ===")
    
    basica()
    loteGrande() 
    orden()
    multiple()
    
    IO.puts("=== Fin pruebas ===")
  end
  
  defp basica do
    IO.puts("1. Prueba básica")
    {:ok, server} = Servidor.start(3)
    
    jobs = [
      fn -> 1 + 1 end,
      fn -> 2 * 2 end,
      fn -> String.upcase("hola") end
    ]
    
    resultados = Servidor.run_batch(server, jobs)
    esperado = [2, 4, "HOLA"]
    
    if resultados == esperado do
      IO.puts("BASICOS: #{inspect(resultados)}")
    else
      IO.puts("BASICOS: Esperaba #{inspect(esperado)}, obtuve #{inspect(resultados)}")
    end
    
    Servidor.stop(server)
  end
  
  defp loteGrande do
    IO.puts("2. Prueba lote demasiado grande")
    {:ok, server} = Servidor.start(2)
    
    jobsGrandes = [fn -> 1 end, fn -> 2 end, fn -> 3 end]
    resultado = Servidor.run_batch(server, jobsGrandes)
    
    if resultado == {:error, :lote_demasiado_grande} do
      IO.puts("LOTE GRANDE: Rechazado")
    else
      IO.puts("LOTE GRANDE: Esperaba error, obtuve #{inspect(resultado)}")
    end
    
    Servidor.stop(server)
  end
  
  defp orden do 
    IO.puts("3. Prueba orden de resultados")
    {:ok, server} = Servidor.start(3)
    
    jobs = [
      fn -> :timer.sleep(300); :primero end,
      fn -> :timer.sleep(100); :tercero end,
      fn -> :timer.sleep(200); :segundo end
    ]
    
    resultados = Servidor.run_batch(server, jobs)
    esperado = [:primero, :tercero, :segundo] 
    
    if resultados == esperado do
      IO.puts("ORDEN: #{inspect(resultados)}")
    else
      IO.puts("ORDEN: Esperaba #{inspect(esperado)}, obtuve #{inspect(resultados)}")
    end
    
    Servidor.stop(server)
  end
  
  defp multiple do 
    IO.puts("4. Prueba múltiples ejecuciones")
    {:ok, server} = Servidor.start(2)
    
    lote1 = Servidor.run_batch(server, [fn -> 1 end, fn -> 2 end])
    lote2 = Servidor.run_batch(server, [fn -> 3 end])
    lote3 = Servidor.run_batch(server, [fn -> 4 end, fn -> 5 end])
    
    if lote1 == [1, 2] and lote2 == [3] and lote3 == [4, 5] do
      IO.puts("MULTIPLE: Todos los lotes ejecutados correctamente")
    else
      IO.puts("MULTIPLE: Problema con lotes múltiples")
    end
    
    Servidor.stop(server)
  end

end

