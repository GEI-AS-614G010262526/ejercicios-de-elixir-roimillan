defmodule GestorRecursosDistribuido do

#FUNCIONES PUBLICAS
#IGUAL QUE EL GESTOR NO DISTRIBUIDO, PERO USANDO :GLOBAL PARA REGISTRAR Y LOCALIZAR EL PROCESO
#SE PUEDE USAR DESDE CUALQUIER NODO CONECTADO

  #Creación del gestor de recursos distribuido. Registra el nombre globalmente
  def start(recursos) do
    pid = spawn(fn -> loop(recursos, []) end)
    :global.register_name(:gestor, pid)  
    {:ok, pid}
  end

  #El cliente pide un recurso 
  def alloc do
    case :global.whereis_name(:gestor) do
      :undefined ->
        {:error, :gestor_no_encontrado}
      gestor_pid ->
        send(gestor_pid, {:alloc, self()})
        receive do
          respuesta -> respuesta
        end
    end
  end

  #Libera un recurso, si es suyo 
  def release(recurso) do
    case :global.whereis_name(:gestor) do
      :undefined ->
        {:error, :gestor_no_encontrado}
      gestor_pid ->
        send(gestor_pid, {:release, self(), recurso})
        receive do
          respuesta -> respuesta
        end
    end
  end

  #Consulta recursos disponibles 
  def avail do
    case :global.whereis_name(:gestor) do
      :undefined ->
        {:error, :gestor_no_encontrado}
      gestor_pid ->
        send(gestor_pid, {:avail, self()})
        receive do
          n -> n
        end
    end
  end

  # Para el gestor distribuido
  def stop do
    case :global.whereis_name(:gestor) do
      :undefined -> :ok
      gestor_pid -> 
        :global.unregister_name(:gestor)
        Process.exit(gestor_pid, :normal)
        :ok
    end
  end

  #FUNCIONES PRIVADAS  
  #Bucle principal del gestor de recursos (misma lógica)
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