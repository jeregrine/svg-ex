defmodule SVG.Utils do
  @doc """
    Converts a string of points `1,2 3,4` to a list of points `[{1,2}, {3,4}]`
    ## Examples

        iex> SVG.Utils.points_to_vector("1,2 3,4")
        [[1,2], [3,4]]
  """
  def points_to_vector(str) do
    str
    |> String.trim()
    |> String.split(" ")
    |> Enum.map(fn s ->
      s
      |> String.trim()
      |> String.split(",")
      |> Enum.map(fn s ->
        s
        |> String.trim()
        |> string_to_numeric()
      end)
    end)
  end

  def vector_to_string(vector) do
    Enum.map(vector, fn [x, y] ->
      "#{x},#{y}"
    end)
    |> Enum.join(" ")
  end

  @doc """
    Calculates the bounds of a list of points.
  """
  def bounds_of_points(points) do
    {xmin, xmax} = Enum.min_max(Enum.map(points, fn [x, _] -> x end))
    {ymin, ymax} = Enum.min_max(Enum.map(points, fn [_, y] -> y end))

    [
      [xmin, ymin],
      [xmax, ymin],
      [xmax, ymax],
      [xmin, ymax]
    ]
  end

  @doc """
    Returns the dimensions of the bounding box defined by points.
  """
  def bounding_box_dimensions(points) do
    [[xmin, ymin], _, [xmax, ymax], _] = bounds_of_points(points)
    [xmax - xmin, ymax - ymin]
  end

  @doc """
    Calculates the arithmetic mean position of the given `points`.
    ## Examples

        iex> SVG.Utils.centroid_of_points([[1,2], [3,4]])
        [2.0, 3.0]
  """
  def centroid_of_points(points) do
    Enum.reduce(points, {0, 0}, fn [x, y], {accx, accy} ->
      {x + accx, y + accy}
    end)
    |> then(fn {accx, accy} ->
      [rnd(accx / length(points)), rnd(accy / length(points))]
    end)
  end

  @doc """
    Formats a tuple {`k` `v`} from a transform map into an inline-able string.
    ## Examples

      iex> SVG.Utils.fa_to_str({:rotate, [0, 90, 0]})
      "rotate(0 90 0)"
  """
  def fa_to_str({fun, args}) do
    "#{fun}(#{Enum.join(args, " ")})"
  end

  @doc """
    Parses a function string to fa tuple.

    ## Examples

        iex> SVG.Utils.str_to_fa("rotate(0 90.10 0)")
        {:rotate, [0, 90.10, 0]}
  """
  def str_to_fa(str) do
    [fun, args] = String.split(str, "(")
    [args, ""] = String.split(args, ")")
    {String.to_atom(fun), String.split(args, " ") |> Enum.map(&string_to_numeric/1)}
  end

  @doc """
    ## Examples

        iex> SVG.Utils.vector_add([1,2], [3,4])
        [4,6]
  """
  def vector_add(a, b) do
    Enum.zip_with([a, b], fn [x, y] -> x + y end)
  end

  @doc """
    ## Examples

        iex> SVG.Utils.vector_sub([1,2], [3,4])
        [-2,-2]
  """
  def vector_sub(a, b) do
    Enum.zip_with([a, b], fn [x, y] -> x - y end)
  end

  @doc """
    ## Examples

        iex> SVG.Utils.vector_mult([1,2], [3,4])
        [3,8]
  """
  def vector_mult(a, b) do
    Enum.zip_with([a, b], fn [x, y] -> x * y end)
  end

  @doc """
    ## Examples

        iex> SVG.Utils.vector_div([3,4], [1,2])
        [3.0, 2.0]
  """
  def vector_div(a, b) do
    Enum.zip_with([a, b], fn [x, y] -> x / y end)
  end

  @doc """
    Rotates 2d point `pt` around the origin by `deg` in the counter-clockwise direction.

    ## Examples

        iex> SVG.Utils.rotate_point([1,2], 90)
        [-2.0, 0.99999]
  """
  def rotate_point([x, y], deg) do
    rad = deg_to_rad(deg)
    c = :math.cos(rad)
    s = :math.sin(rad)

    new_x = rnd(x * c - y * s)
    new_y = rnd(x * s + y * c)

    [new_x, new_y]
  end

  @doc """
  Rotates point `pt` around `center` by `deg` in the counter-clockwise direction.
  ## Examples

      iex> SVG.Utils.rotate_point_around_center([1,2], 90, [0,0])
      [-2.0,0.99999]
  """

  def rotate_point_around_center(pt, deg, center) do
    translated_pt = vector_add(pt, vector_mult([-1, -1], center))
    rotated_pt = rotate_point(translated_pt, deg)
    result_pt = vector_add(rotated_pt, center)

    result_pt
  end

  def rnd(num) when is_float(num) do
    Float.round(num, 5)
  end

  def rnd(n), do: n

  def deg_to_rad(deg) do
    rnd(deg * (:math.pi() / 180))
  end

  def rad_to_deg(rad) do
    rnd(rad * (180 / :math.pi()))
  end

  @doc"""
    Computes the distance between two points `a` and `b`.
    #Examples

        iex> SVG.Utils.distance([1,2], [3,4])
        2.82843
  """
  def distance(a, b) do
    v = vector_sub(b, a)

    vector_mult(v,v)
    |> Enum.sum()
    |> :math.sqrt()
    |> rnd()
  end

  @doc """
    Merge a style map into the given element.
  """
  def style({elem, props}, style) do
    {elem, Map.merge(props, style)}
  end

  def style({elem, props, content}, style) do
    {elem, Map.merge(props, style), content}
  end

  @spec string_to_numeric(binary()) :: float() | number() | nil
  def string_to_numeric(val) when is_binary(val),
    do: _string_to_numeric(Regex.replace(~r{[^\d\.]}, val, ""))

  defp _string_to_numeric(val) when is_binary(val),
    do: _string_to_numeric(Integer.parse(val), val)

  defp _string_to_numeric(:error, _val), do: nil
  defp _string_to_numeric({num, ""}, _val), do: num
  defp _string_to_numeric({num, ".0"}, _val), do: num
  defp _string_to_numeric({_num, _str}, val), do: elem(Float.parse(val), 0)
end
