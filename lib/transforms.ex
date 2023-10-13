defmodule SVG.Transforms do
  @moduledoc """
    Provides functions for computing and transforming properties of the SVG elements.

    #TODO Scale
    #TODO OFFSET
  """

  alias SVG.Utils, as: U
  alias SVG.Paths

  @doc """
    Cacluates the axis-aligned-bounding-box of an element or list of elements.
  """
  def bounds(elem) when is_list(elem) do
    Enum.flat_map(elem, &bounds/1)
    |> U.bounds_of_points()
  end

  def bounds({:circle, %{cx: cx, cy: cy, r: r}}) do
    Enum.map([[r, 0], [0, r], [-r, 0], [0, -r]], fn v ->
      U.vector_add([cx, cy], v)
    end)
    |> U.bounds_of_points()
  end

  def bounds({:ellipse, %{cx: cx, cy: cy, rx: rx, ry: ry} = props}) do
    bounding_box =
      Enum.map([[rx, 0], [0, ry], [-rx, 0], [0, -ry]], fn v ->
        U.vector_add(v, [cx, cy])
      end)

    points =
      Enum.map([[rx, 0], [0, ry], [-rx, 0], [0, -ry]], fn v ->
        U.vector_add(v, [cx, cy])
      end)

    [deg, mx, my] = get_rotate(props)

    obb =
      Enum.map(bounding_box, fn v ->
        U.rotate_point_around_center(v, deg, [mx, my])
      end)

    xpts =
      Enum.map(points, fn v ->
        U.rotate_point_around_center(v, deg, [mx, my])
      end)

    small = U.bounds_of_points(xpts)
    large = U.bounds_of_points(obb)

    Enum.zip_with([small, large], fn a, b ->
      U.centroid_of_points([a, b])
    end)
    |> U.bounds_of_points()
  end

  def bounds({:line, %{x1: x1, y1: y1, x2: x2, y2: y2}}) do
    U.bounds_of_points([[x1, y1], [x2, y2]])
  end

  def bounds({t, %{points: points}}) when t in [:polygon, :polyline] do
    points
    |> U.points_to_vector()
    |> U.bounds_of_points()
  end

  def bounds({t, %{x: x, y: y, width: w, height: h} = props}) when t in [:rect, :image] do
    [deg, mx, my] = get_rotate(props)

    [
      [x, y],
      [x + w, y],
      [x + w, y + h],
      [x, y + h]
    ]
    |> Enum.map(fn v ->
      U.rotate_point_around_center(v, deg, [mx, my])
    end)
    |> U.bounds_of_points()
  end

  # busted lol
  def bounds({:text, %{x: x, y: y, "font-size": fs} = props, text}) do
    [deg, _mx, _my] = get_rotate(props)
    ar = 0.6
    h = fs
    hh = h / 2.0
    hw = ar * h * String.length(text) / 2.0

    [
      [x - hw, y - hh],
      [x + hw, y - hh],
      [x + hw, y + hh],
      [x - hw, y + hh]
    ]
    |> Enum.map(fn v ->
      U.rotate_point_around_center(v, deg, [x, y])
    end)
    |> U.bounds_of_points()
  end

  def bounds({:g, _, content}) do
    Enum.flat_map(content, &bounds/1)
    |> U.bounds_of_points()
  end

  def bounds({:path, _}=elem) do
    Paths.bounds(elem)
  end

  @doc """
    Calculates the arithmetic mean position of the given `elem`.
  """
  def centroid(elem) when is_list(elem) do
    Enum.flat_map(elem, &centroid/1)
    |> U.centroid_of_points()
  end

  def centroid({c, %{cx: cx, cy: cy}}) when c in [:circle, :ellipse] do
    [cx, cy]
  end

  def centroid({:line, %{x1: x1, y1: y1, x2: x2, y2: y2}}) do
    U.centroid_of_points([[x1, y1], [x2, y2]])
  end

  def centroid({p, %{points: points}}) when p in [:points, :polygon, :polyline] do
    points
    |> U.points_to_vector()
    |> U.centroid_of_points()
  end

  def centroid({r, %{x: x, y: y, height: h, width: w}}) when r in [:rect, :image] do
    [x + w / 2.0, y + h / 2.0]
  end

  # busted lol
  def centroid({:text, %{x: x, y: y}, contents}) do
    [x, y]
  end

  def centroid({:path, _} = elem) do
    Paths.centroid(elem)
  end

  def centroid({:g, _, content}) do
    Enum.map(content, &centroid/1)
    |> U.centroid_of_points()
  end

  @doc """
  Translates `elem` by [`x` `y`].
  """
  def translate(elem, [x, y]) when is_list(elem) do
    Enum.map(elem, fn e -> translate(e, [x, y]) end)
  end

  def translate({c, %{cx: cx, cy: cy} = props}, [x, y]) when c in [:circle, :ellipse] do
    [deg, mx, my] = get_rotate(props)
    fa = {:rotate, [deg, cx + x, cy + y]} |> U.fa_to_str()

    {:circle,
     Map.merge(props, %{
       cx: cx + x,
       cy: cy + y,
       transform: fa
     })}
  end

  def translate({:line, %{x1: x1, y1: y1, x2: x2, y2: y2} = props}, [x, y]) do
    {:line,
     Map.merge(props, %{
       x1: x1 + x,
       y1: y1 + y,
       x2: x2 + x,
       y2: y2 + y
     })}
  end

  def translate({l, %{points: points} = props}, [x, y]) when l in [:polygon, :polyline] do
    {l,
     Map.merge(props, %{
       points:
         points
         |> U.points_to_vector()
         |> Enum.map(fn [px, py] -> [px + x, py + y] end)
         |> U.vector_to_string()
     })}
  end

  def translate({r, %{x: x1, y: y1} = props}, [x, y]) when r in [:rect, :image] do
    [deg, mx, my] = get_rotate(props)
    fa = {:rotate, [deg, mx + x, my + y]} |> U.fa_to_str()

    {r,
     Map.merge(props, %{
       x: x + x1,
       y: y + y1,
       transform: fa
     })}
  end

  def translate({:text, props, contents}, [x, y]) do
    {_, props} = translate({:rect, props}, [x, y])
    {:text, props, contents}
  end

  def translate({:path, _} = elem, t) do
    Paths.translate(elem, t)
  end

  def translate({:g, props, content}, [x, y]) do
    {:g, props, Enum.map(content, fn e -> translate(e, [x, y]) end)}
  end

  @doc """
  Rotate an element by using the SVG transform property.
  This function is used to transform elements that cannot 'bake' the transform into their other geometric properties.
  For example, the ellipse and circle elements have only center and radius properties which cannot affect orientation.
  """
  def rotate_by_transform({type, props}, deg) do
    [d, mx, my] = get_rotate(props)
    fa = {:rotate, [d + deg, mx, my]} |> U.fa_to_str()
    {type, Map.merge(props, %{transform: fa})}
  end

  def rotate_by_transform({type, props, content}, deg) do
    {type, props} = rotate_by_transform({type, props}, deg)
    {type, props, content}
  end

  @doc """
    Rotate `element` by `deg` degrees around its centroid.
  """
  def rotate(element, deg) when is_list(element) do
    Enum.map(element, fn e -> rotate(e, deg) end)
  end

  def rotate({k, props}, deg) when k in [:circle, :ellipse] do
    rotate_by_transform({k, props}, deg)
  end

  def rotate({:line, %{x1: x1, y1: y1, x2: x2, y2: y2} = props}, deg) do
    line = [[x1, y1], [x2, y2]]
    cent = U.centroid_of_points(line)

    [[nx1, ny1], [nx2, ny2]] =
      Enum.map(line, fn pts ->
        pts
        |> U.vector_sub(cent)
        |> U.rotate_point(deg)
        |> U.vector_add(cent)
      end)

    {:line, Map.merge(props, %{x1: nx1, y1: ny1, x2: nx2, y2: ny2})}
  end

  def rotate({p, %{points: points} = props}, deg) when p in [:polygon, :polyline] do
    vec = U.points_to_vector(points)
    cent = centroid({p, props})

    {p,
     Map.merge(props, %{
       points:
         Enum.map(vec, fn pts ->
           pts
           |> U.vector_sub(cent)
           |> U.rotate_point(deg)
           |> U.vector_add(cent)
         end)
         |> U.vector_to_string()
     })}
  end

  def rotate({r, props}, deg) when r in [:rect, :image, :text] do
    [cx, cy] = centroid({r, props})
    [d, _mx, _my] = get_rotate(props)
    fa = {:rotate, [d + deg, cx, cy]} |> U.fa_to_str()

    {r, Map.merge(props, %{transform: fa})}
  end

  def rotate({:text, props, text}, deg) do
    rotate_by_transform({:text, props, text}, deg)
  end

  def rotate({:path, _}=elem, deg) do
    Paths.rotate(elem, deg)
  end

  def rotate({:g, props, content} = el, deg) do
    [gcx, gcy] =
      bounds(el)
      |> U.centroid_of_points()

    xfcontent =
      Enum.map(content, fn child ->
        ch = translate(child, [-gcx, -gcy])

        ctr =
          if elem(ch, 0) == :g do
            ch
            |> bounds()
            |> U.centroid_of_points()
          else
            centroid(ch)
          end

        xfm =
          ctr
          |> U.rotate_point(deg)
          |> U.vector_add([gcx, gcy])

        ch
        |> translate(U.vector_mult([-1, -1], ctr))
        |> rotate(deg)
        |> translate(xfm)
      end)

    {:g, props, xfcontent}
  end

  defp get_rotate(props) do
    transform = Map.get(props, :transform, "rotate(0 0 0)")
    {:rotate, args} = U.str_to_fa(transform)
    args
  end
end
