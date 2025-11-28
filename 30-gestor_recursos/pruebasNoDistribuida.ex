defmodule PruebasGestorRecursos do
  def ejecutarTodas do
    IO.puts("=== Pruebas Gestor de Recursos ===")
    
    allocBasico()
    releaseBasico()
    availBasico()
    sinRecursos()
    recursoNoReservado()
    multiplesRecursosMismoCliente()
    verificacionPropiedad()
    estadoConsistente()
    
    IO.puts("=== Fin pruebas ===")
  end
  
  defp limpiarGestor do
    GestorRecursos.stop()
  end
  
  defp allocBasico do
    IO.puts("1. Prueba alloc básico")
    GestorRecursos.start([:recurso1, :recurso2])
    
    resultado1 = GestorRecursos.alloc()
    resultado2 = GestorRecursos.alloc()
    
    if resultado1 == {:ok, :recurso1} and resultado2 == {:ok, :recurso2} do
      IO.puts("ALLOC: Recursos asignados en orden")
    else
      IO.puts("ALLOC: Error en asignación básica")
    end
    
    limpiarGestor()
  end
  
  defp releaseBasico do
    IO.puts("2. Prueba release básico")
    GestorRecursos.start([:libre1, :libre2])
    
    {:ok, recurso} = GestorRecursos.alloc()
    resultadoRelease = GestorRecursos.release(recurso)
    
    if resultadoRelease == :ok do
      IO.puts("RELEASE: Recurso liberado correctamente")
    else
      IO.puts("RELEASE: Error al liberar recurso")
    end
    
    limpiarGestor()
  end
  
  defp availBasico do
    IO.puts("3. Prueba avail básico")
    GestorRecursos.start([:x, :y, :z])
    
    disponiblesInicial = GestorRecursos.avail()
    GestorRecursos.alloc()
    disponiblesDespues = GestorRecursos.avail()
    
    if disponiblesInicial == 3 and disponiblesDespues == 2 do
      IO.puts("AVAIL: Conteo correcto - antes: #{disponiblesInicial}, después: #{disponiblesDespues}")
    else
      IO.puts("AVAIL: Error en conteo de disponibles")
    end
    
    limpiarGestor()
  end
  
  defp sinRecursos do
    IO.puts("4. Prueba sin recursos")
    GestorRecursos.start([:unico])
    
    GestorRecursos.alloc()
    resultado = GestorRecursos.alloc()
    
    if resultado == {:error, :sin_recursos} do
      IO.puts("SIN_RECURSOS: Correctamente rechazado")
    else
      IO.puts("SIN_RECURSOS: Esperaba error, obtuve #{inspect(resultado)}")
    end
    
    limpiarGestor()
  end
  
  defp recursoNoReservado do
    IO.puts("5. Prueba recurso no reservado")
    GestorRecursos.start([:r1, :r2])
    
    resultado = GestorRecursos.release(:recurso_inexistente)
    
    if resultado == {:error, :recurso_no_reservado} do
      IO.puts("NO_RESERVADO: Correctamente rechazado")
    else
      IO.puts("NO_RESERVADO: Esperaba error, obtuve #{inspect(resultado)}")
    end
    
    limpiarGestor()
  end
  
  defp multiplesRecursosMismoCliente do
    IO.puts("6. Prueba múltiples recursos mismo cliente")
    GestorRecursos.start([:m1, :m2, :m3])
    
    {:ok, r1} = GestorRecursos.alloc()
    {:ok, _r2} = GestorRecursos.alloc()
    
    GestorRecursos.release(r1)
    {:ok, r3} = GestorRecursos.alloc()
    
    if r1 != r3 do
      IO.puts("MULTIPLES: Cliente puede tener múltiples recursos")
    else
      IO.puts("MULTIPLES: Error con múltiples recursos")
    end
    
    limpiarGestor()
  end
  
  defp verificacionPropiedad do
    IO.puts("7. Prueba verificación propiedad")
    GestorRecursos.start([:p1, :p2])
    
    {:ok, recurso} = GestorRecursos.alloc()
    
    resultado = spawn(fn -> 
      send(:gestor, {:release, self(), recurso})
      receive do
        _respuesta -> :ok
      end
    end)
    
    :timer.sleep(100)
    
    if Process.alive?(resultado) do
      IO.puts("PROPIEDAD: Verificación activa")
    else
      IO.puts("PROPIEDAD: Proceso terminado")
    end
    
    limpiarGestor()
  end
  
  defp estadoConsistente do
    IO.puts("8. Prueba estado consistente")
    GestorRecursos.start([:e1, :e2, :e3])
    
    disponiblesInicial = GestorRecursos.avail()
    {:ok, r1} = GestorRecursos.alloc()
    {:ok, _r2} = GestorRecursos.alloc()
    disponiblesMitad = GestorRecursos.avail()
    GestorRecursos.release(r1)
    disponiblesFinal = GestorRecursos.avail()
    
    if disponiblesInicial == 3 and disponiblesMitad == 1 and disponiblesFinal == 2 do
      IO.puts("ESTADO: Consistente - #{disponiblesInicial}→#{disponiblesMitad}→#{disponiblesFinal}")
    else
      IO.puts("ESTADO: Inconsistente en el flujo")
    end
    
    limpiarGestor()
  end
end