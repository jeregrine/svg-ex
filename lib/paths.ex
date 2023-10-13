defmodule SVG.Paths do
  @moduledoc """
    Provides functions for generating and manipulating SVG path elements.

    Every element provided in `SVG.Elemets` has an equivalent function in this namespace that emits path elements with a properly formatted `d` property.

    The path element has a small Domain Specific Language to create compound shapes and curves. This includes the following commands:

    M = moveto
    L = lineto
    H = horizontal lineto
    V = vertical lineto
    C = curveto
    S = smooth curveto
    Q = quadratic Bézier curve
    T = smooth quadratic Bézier curveto
    A = elliptical Arc
    Z = closepath
  """

  alias SVG.Utils, as: U

  def path(d) do
    {:path, %{d: d, "fill-rule": "evenodd"}}
  end

  def arc(start, center, deg) do
    r = U.distance(start, center)
    angle = 0
    b = U.rotate_point_around_center(start, deg, center)

    laf = if deg <= 180, do: 0, else: 1

    open = point_m(start)

    [
      %{
        command: "A",
        coordsys: :abs,
        input: [r, r, angle, laf, 1, b]
      },
      open
    ]
    |> path()
  end

  @doc """
    Generates a valid string for the path element `d` property from a list of command maps `cmds`.
    ## Examples

      iex> SVG.Paths.cmd_to_path_string([%{command: "M", coordsys: :abs, input: []}
  """
  def cmd_to_path_string(%{command: command, coordsys: coordsys, input: input}) do
    c =
      if coordsys == :abs do
        command
      else
        String.downcase(command)
      end

    input =
      input
      |> Enum.map(&point_str/1)
      |> Enum.join(" ")

    "#{c}#{input}"
  end

  def cmd_to_path_string(cmds) when is_list(cmds) do
    start = hd(cmds)

    cmds =
      if hd(cmds) == %{command: "M"} do
        cmds
      else
        [
          %{command: "M", coordsys: :abs, input: Map.get(start, :cursor, [0, 0]), cursor: [0, 0]}
          | cmds
        ]
      end

    cmds
    |> Enum.map(&cmd_to_path_string/1)
    |> Enum.join(" ")
  end

  def point_str([a, b]) do
    "#{a},#{b}"
  end
  def point_str(a) do
    "#{a}"
  end

  defp point_m(pt) do
    %{command: "M", coordsys: :abs, input: List.wrap(pt)}
  end

  @doc """
    Doesn't fully work for A.

    """
  defp cmd_to_point(%{command: "A", input: [rx, laf, x, y], cursor: cursor}) do
    b = [x, y]
    ctr = U.v_add(cursor, [rx, 0])
    sa = U.angle_from_pts(cursor, ctr, b)
    angle = if laf == 1, do: 360 - sa, else: sa
    mids =
      0..angle/90
      |> tail()
      |> Enum.map(fn deg ->
        U.rotate_point_around_center(cursor, deg, ctr)
      end)

    [cursor | mids] ++ b
  end

  defp cmd_to_point(%{input: input}) do
    Enum.partition(input, 2)
  end

  def translate(elem, [x, y]) do
    elem
  end

  @docs "Rotate the path `elem` around its centroid by `deg` degrees."
  def rotate({:path, %{d: cmds}=props} = el, deg) do
    ctr = centroid(el)
    xcmds = Enum.map(cmds, fn c ->
      rotate_path_command(c, ctr, deg)
    end)

    {:path, %{props | d: xcmds}}
  end

  def rotate_path_command(%{command: c, input: input} = cmd, ctr, deg) when c in ~w(M L T) do
    input
    |> U.v_sub(ctr)
    |> U.rotate_pt(deg)
    |> U.v_add(ctr)

    %{cmd | input: input}
  end

  def rotate_path_command(%{command: "Z" } = cmd, _, _) do
    cmd
  end

  def rotate_path_command(%{command: c, input: input} = cmd, ctr, deg) when c in ~w(C S Q) do
    input =
      input
      |>Enum.partition(2)
      |> Enum.map(fn [a, b] ->
        U.v_sub(a, ctr)
        |> U.rotate_pt(deg)
        |> U.v_add(ctr)
      end)


    %{cmd | input: input}
  end

  ;; [rx ry xrot laf swf x y]
  ;; rx, ry do not change
  ;; xrot also no change
  ;; large arc flag and swf again no change
  (defmethod rotate-path-command "A"
    [{:keys [:input] :as m} ctr deg]
    (let [[rx ry xrot laf swf ox oy] input
          [nx ny] (-> [ox oy]
                      (u/v- ctr)
                      (u/rotate-pt deg)
                      (u/v+ ctr))]
      (assoc m :input [rx ry (+ xrot deg) laf swf nx ny])))



  @doc "Calculates the axis-aligned-bounding-box of the points"
  def bounds({:path, %{d: d}}) do
    d
    |> Enum.flap_map(&cmd_to_point/1)
    |> U.centroid_of_pts()
  end

  @doc "Calculates the arithmetic mean position of the path element by finding all of the points for every command, and fidning the centroid of those points. May be innaccurate for paths with curved elements."
  def centroid({:path, %{d: d}}) do
    d
    |> Enum.flap_map(&cmd_to_point/1)
    |> U.centroid_of_pts()
  end
end
