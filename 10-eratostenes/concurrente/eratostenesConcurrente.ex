defmodule Eratostenes do

	def primos(n) when n < 2 do
		:"n debe ser mayor o igual que 2"
	end

	def primos(n) do
		
		principalPID = self()
		finalizadorPID = spawn_link(fn -> finalizador([], principalPID, 0) end)
		primerFiltro = nil

		primerFiltro =
			Enum.reduce(2..n, primerFiltro, fn numero, filtroActual ->
				case filtroActual do
					nil ->
						send(finalizadorPID, {:primo, numero})
						spawn_link(fn -> filtro(numero, nil, finalizadorPID) end)
					pid ->
						send(pid, {:numero, numero})
						pid
				end
			end)

		send(primerFiltro, :fin)

		receive do
			{:resultado, primos} ->
				primos
		end
		
	end


	defp filtro(primo, siguienteFiltro, finalizadorPID) do
		
		receive do
			
			{:numero, n} ->
				if rem(n, primo) != 0 do
					case siguienteFiltro do
						nil ->
							send(finalizadorPID, {:primo, n})
							nuevoFiltro = spawn_link(fn -> filtro(n, nil, finalizadorPID) end)
							filtro(primo, nuevoFiltro, finalizadorPID)
						siguiente ->
							send(siguiente, {:numero, n})
							filtro(primo, siguiente, finalizadorPID)
					end
				else
					filtro(primo, siguienteFiltro, finalizadorPID)
				end

			:fin ->
				if siguienteFiltro, do: send(siguienteFiltro, :fin)
				send(finalizadorPID, {:fin, self()})
		end
		
	end


	defp finalizador(primos, principalPID, filtrosVivos) do
		
		receive do
			
			{:primo, n} ->
				finalizador([n | primos], principalPID, filtrosVivos + 1)
				
			{:fin, _pid} ->
				if filtrosVivos - 1 == 0 do
					send(principalPID, {:resultado, Enum.reverse(primos)})
				else
					finalizador(primos, principalPID, filtrosVivos - 1)
				end
		end
		
	end
	
end
