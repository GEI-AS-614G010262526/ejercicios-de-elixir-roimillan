defmodule GestorRecursos do

#FUNCIONES PUBLICAS

  #Creación del gestor de recursos. Se le pasan los recursos libres y los asignados
  def start(recursos) do
    pid = spawn(fn -> loop(recursos, []) end)
    Process.register(pid, :gestor)
    {:ok, pid}
  end

  #El cliente pide un recurso y se lo asigna con su pid
  def alloc do
    send(:gestor, {:alloc, self()})
    receive do
      respuesta -> respuesta
    end
  end

  #Libera un recurso, si es suyo
  def release(recurso) do
    send(:gestor, {:release, self(), recurso})
    receive do
      respuesta -> respuesta
    end
  end

  #Consulta recursos disponibles
  def avail do
    send(:gestor, {:avail, self()})
    receive do
      n -> n
    end
  end
  
  #Para el gestor
  def stop do
    case Process.whereis(:gestor) do
      nil -> :ok
      pid -> 
        Process.unregister(:gestor)
        Process.exit(pid, :normal)
        :ok
    end
  end
 
#FUNCIONES PRIVADAS  
  #Bucle principal del gestor de recursos, maneja la casuistica según los mensajes
  defp loop(disponibles, asignados) do
    receive do
      {:alloc, from} ->
        case disponibles do
          [] ->
            send(from, {:error, :sin_recursos})
            loop([], asignados)
          [libre | resto] ->
            send(from, {:ok, libre})
            loop(resto, [{libre, from} | asignados])
        end

      {:release, from, recurso} ->
        if {recurso, from} in asignados do
          send(from, :ok)
          nuevosDisponibles = [recurso | disponibles]
          nuevosAsignados = List.delete(asignados, {recurso, from})
          loop(nuevosDisponibles, nuevosAsignados)
        else
          send(from, {:error, :recurso_no_reservado})
          loop(disponibles, asignados)
        end

      {:avail, from} ->
        send(from, length(disponibles))
        loop(disponibles, asignados)
    end
  end
end