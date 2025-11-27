defmodule Eratostenes do

#Funciones publicas

#N debe de ser mayor o igual que 2
  def primos(n) when n < 2, do: []

#Si es mayor o igual que dos
#Se crea el primer filtro con el primer primo (2)
#Se envian todos los numeros desde el 3 hasta n al primer filtro y este descarta o reenvia
#Una vez se envían todos lo numeros, se envía un mensaje de fin al primer filtro que lo propaga hasta el último y así recogemos la cadena de primos

  def primos(n) do
    primer_filtro = spawn(fn -> filtro(2) end)
    
    Enum.each(3..n, fn i -> send(primer_filtro, {:numero, i}) end)
    send(primer_filtro, {:fin, self()})
    
    receive do
      {:resultado, primos} -> primos
    end
  end

#Funciones privadas

#Función usada para crear los filtros
  defp filtro(primo) do
    filtro(primo, nil)
  end

#Función auxiliar que implementa el comportamiento de cada filtro
#Si recibe un número, comprueba si es divisible por su primo
#Si no lo es, lo reenvía al siguiente filtro o crea uno nuevo si no existe
#Si recibe un mensaje de fin, lo reenvía al siguiente filtro o responde al cliente si no existe siguiente filtro
  
  defp filtro(primo, siguiente) do
    receive do
      {:numero, n} ->
        if rem(n, primo) != 0 do
          case siguiente do
            nil -> 
              nuevo_filtro = spawn(fn -> filtro(n) end)
              filtro(primo, nuevo_filtro)
            pid ->
              send(pid, {:numero, n})
              filtro(primo, siguiente)
          end
        else
          filtro(primo, siguiente)
        end

      {:fin, cliente} ->
        case siguiente do
          nil ->
            send(cliente, {:resultado, [primo]})
          pid ->
            send(pid, {:fin, self()})
            
            receive do
              {:resultado, otros_primos} ->
                send(cliente, {:resultado, [primo | otros_primos]})
            end
        end
    end
  end
end