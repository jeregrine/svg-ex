defmodule SVG.Elements do
  @moduledoc """
  Provides functions to generate the renderable SVG.Elements..
  Every function in this module emits tuple-style data structures,
  similar to {:tag, %{prop: "value"}}, except `g` (group) and `text`,
  which emit {:tag, %{prop: "value"}, "content"}.

  All functions in this module emit the primitive elements of an SVG image.
  These primitives are the basis for further manipulation using transform functions.

  One notable element which is not provided is `path`. Since path elements have
  a more complex property specification, a separate module could be dedicated to
  path element generation.
  """

  @doc """
  Emits a circle element with radius `r` centered at the origin.

  ## Examples

      iex> SVG.Elements.circle(10)
      {:circle, %{cx: 0, cy: 0, r: 10}}

  """
  def circle(r) do
    {:circle, %{cx: 0, cy: 0, r: r}}
  end

  @doc """
  Emits an ellipse element with x-axis radius `rx` and y-axis radius `ry` centered at the origin.

  ## Examples

      iex> SVG.Elements.ellipse(10, 20)
      {:ellipse, %{cx: 0, cy: 0, rx: 10, ry: 20}}

  """
  def ellipse(rx, ry) do
    {:ellipse, %{cx: 0, cy: 0, rx: rx, ry: ry}}
  end

  @doc """
  Emits a line element starting at 2D point `a` and ending at 2D point `b`.

  ## Examples

      iex> SVG.Elements.line([0, 1], [2, 3])
      {:line, %{x1: 0, y1: 1, x2: 2, y2: 3}}
  """
  def line([ax, ay], [bx, by]) do
    {:line, %{x1: ax, y1: ay, x2: bx, y2: by}}
  end

  @doc """
  Emits a polygon element with 2D points from list `points`.
  Polygon elements have a closed path.

  ## Examples

      iex> SVG.Elements.polygon([[0, 0], [10, 20], [40, 50], [20, 10]])
      {:polygon, %{points: "0,0 10,20 40,50 20,10"}}
  """
  def polygon(points) do
    points_str =
      points
      |> Enum.map(fn [x, y] ->
        "#{x},#{y}"
      end)
      |> Enum.join(" ")

    {:polygon, %{points: points_str}}
  end

  @doc """
  Emits a polyline element with 2D points from list `[x, y]` points.
  Polyline elements have an open path.
  ## Examples

      iex> SVG.Elements.polyline([[0, 0], [10, 20], [40, 50], [20, 10]])
      {:polyline, %{points: "0,0 10,20 40,50 20,10"}}
  """
  def polyline(points) do
    points_str =
      points
      |> Enum.map(fn [x, y] ->
        "#{x},#{y}"
      end)
      |> Enum.join(" ")

    {:polyline, %{points: points_str}}
  end

  @doc """
  Emits a rect element of width `w` and height `h` centered at the origin.

  ## Examples

      iex> SVG.Elements.rect(10, 20)
      {:rect, %{width: 10, height: 20, x: -5.0, y: -10.0}}
  """
  def rect(w, h) do
    {:rect, %{width: w, height: h, x: w / -2.0, y: h / -2.0}}
  end

  @doc """
  Emits an image element of the image specified at `url`, of width `w`, and height `h` centered at the origin.

  ## Examples

      iex> SVG.Elements.image("img.png", 10, 20)
      {:image, %{href: "img.png", width: 10, height: 20, x: -5.0, y: -10.0}}
  """
  def image(url, w, h) do
    {:image, %{href: url, width: w, height: h, x: w / -2.0, y: h / -2.0}}
  end

  @doc """
  Emits a text element containing `text` of font-size 12pt.
  By default, text is centered at the origin by setting text-anchor='middle' and dominant-baseline='middle'.
  ## Examples

      iex> SVG.Elements.text("hello world")
      {:text, %{x: 0, y: 0, "font-size": 12, "text-anchor": "middle", "dominant-baseline": "middle"}, "hello world"}
  """
  def text(text) do
    {:text,
     %{x: 0, y: 0, "font-size": 12, "text-anchor": "middle", "dominant-baseline": "middle"}, text}
  end

  @doc """
  Emits a g (group) element.
  ## Examples

      iex> SVG.Elements.g([])
      {:g, %{}}

      iex> SVG.Elements.g({:circle, %{x: 0, y: 0, r: 10}})
      {:g, %{}, [{:circle, %{x: 0, y: 0, r: 10}}] }
  """
  def g([]), do: {:g, %{}}

  def g(content) do
    {:g, %{}, List.wrap(content)}
  end
end
