defmodule Eratostenes do
	def primos(n) when n < 2 do
		:"n debe de ser mayor o igual que 2"
	end

	def primos(n) do
		posiblesPrimos = Enum.to_list(2..n)
		Enum.reverse(obtenerPrimos(posiblesPrimos, []))
	end

	defp obtenerPrimos([], primos) do
		primos
	end

	defp obtenerPrimos([primo | restoNumeros], primos) do
		primosFiltrados = Enum.filter(restoNumeros, fn i -> rem(i, primo) != 0 end)
		obtenerPrimos(primosFiltrados, [primo | primos])
	end
end

