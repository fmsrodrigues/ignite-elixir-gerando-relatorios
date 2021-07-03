defmodule GenReport do
  alias GenReport.Parser

  @names [
    "daniele",
    "mayk",
    "giuliano",
    "cleiton",
    "jakeliny",
    "joseph",
    "diego",
    "danilo",
    "rafael",
    "vinicius"
  ]

  @months [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]

  def build do
    {:error, "Insira o nome de um arquivo"}
  end

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Insira uma lista com os nomes dos arquivos"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  defp sum_values([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = Map.put(all_hours, name, all_hours[name] + hours)

    hours_per_month =
      Map.put(
        hours_per_month,
        name,
        Map.put(hours_per_month[name], month, hours_per_month[name][month] + hours)
      )

    hours_per_year =
      Map.put(
        hours_per_year,
        name,
        Map.put(hours_per_year[name], year, hours_per_year[name][year] + hours)
      )

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)

    hours_per_month = merge_maps(hours_per_month1, hours_per_month2, &merge_maps/2)

    hours_per_year = merge_maps(hours_per_year1, hours_per_year2, &merge_maps/2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp merge_maps(map1, map2, f) do
    Map.merge(map1, map2, fn _key, val1, val2 -> f.(val1, val2) end)
  end

  defp report_acc do
    all_hours = Enum.into(@names, %{}, &{&1, 0})
    empty_months = Enum.into(@months, %{}, &{&1, 0})
    hours_per_month = Enum.into(@names, %{}, &{&1, empty_months})
    empty_years = Enum.into(2016..2020, %{}, &{&1, 0})
    hours_per_year = Enum.into(@names, %{}, &{&1, empty_years})

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
