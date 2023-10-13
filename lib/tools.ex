defmodule SVG.Tools do
  alias SVG.Transforms, as: T
  alias SVG.Elements, as: E
  alias SVG.Utils, as: U
  alias SVG.Paths

  def render(list) when is_list(list) do
    Enum.map(list, fn elem ->
      render(elem)
    end)
    |> Enum.join("\n")
    |> String.trim()
  end

  def render({elem, props, content}) do
    """
    <#{elem} #{to_attr(props)}>
      #{render(content)}
    </#{elem}>
    """
    |> String.trim()
  end

  def render({elem, props}) do
    "<#{elem} #{to_attr(props)} />"
    |> String.trim()
  end

  def render(str) when is_binary(str) do
    str
  end

  def to_attr(props) do
    Enum.map(props, fn
      {:d, v} -> ~s(#{k}="#{Paths.cmd_to_path_string(v)}")
      {k, v} -> ~s(#{k}="#{v}")
    end)
    |> Enum.join(" ")
  end

  @doc "Add some basic debugging geometry to `elem`."
  def show_debug(elem) do
    centroid = T.centroid(elem)
    bounds = T.bounds(elem)

    E.g([
      elem,
      E.g([
        E.polygon(bounds)
        |> U.style(%{fill: "none", stroke: "red", "stroke-width": "1px", opacity: 0.5}),
        E.circle(3)
        |> U.style(%{fill: "red", opacity: 0.5})
        |> T.translate(centroid)
      ])
    ])
  end
end
