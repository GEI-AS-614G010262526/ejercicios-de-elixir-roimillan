defmodule PruebasDistribuida do
  def ejecutarTodas do
    IO.puts("=== PRUEBAS REALES DISTRIBUIDAS ===")
    
    IO.puts("1.Verificando conexión entre nodos...")
    IO.puts("Nodos conectados: #{inspect(Node.list())}")
    
    IO.puts("2.Probando que el gestor está accesible...")
    gestorAccesible()
    
    IO.puts("3.Probando operaciones desde nodo remoto...")
    operacionesRemotas()
    
    
    IO.puts("=== FIN PRUEBAS ===")
  end
  
  defp gestorAccesible do
    case :global.whereis_name(:gestor) do
      :undefined ->
        IO.puts("ERROR: Gestor no encontrado desde nodo remoto")
      pid ->
        IO.puts("Gestor encontrado: #{inspect(pid)}")
    end
  end
  
  defp operacionesRemotas do
    
    disponibles = GestorRecursosDistribuido.avail()
    IO.puts("   Recursos disponibles: #{disponibles}")
    
    {:ok, recurso} = GestorRecursosDistribuido.alloc()
    IO.puts("Recurso asignado desde nodo remoto: #{recurso}")
    
    nuevosDisponibles = GestorRecursosDistribuido.avail()
    IO.puts("Recursos después de asignar: #{nuevosDisponibles}")
    
    :ok = GestorRecursosDistribuido.release(recurso)
    IO.puts("Recurso liberado desde nodo remoto")
    
    finales = GestorRecursosDistribuido.avail()
    IO.puts("Recursos finales: #{finales}")
    
    if finales == disponibles do
      IO.puts("Todas las operaciones funcionan desde nodo remoto")
    else
      IO.puts("Error en operaciones remotas")
    end
  end
  
end