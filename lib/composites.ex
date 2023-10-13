defmodule SVG.Composites do
  @moduledoc """
   Provides functions that combine transforms and primitive elements to make more complicated shapes.
   Additionally, the SVG container function is provided here as it relies on SVG.Transforms to allow automatic viewBox setup.
   """

   alias SVG.Elements, as: El
   alias SVG.Transforms, as: Tf
   alias SVG.Utils, as: U

   # Wraps `content` in an SVG container element.
   def svg(content) do
     bounds = Tf.bounds(content)
     [w, h] = U.bounding_box_dimensions(bounds)
     [[x, y], _, _, _] = bounds
     {:svg, %{width: w, height: h, viewBox: "#{x} #{y} #{w} #{h}", xmlns: "http://www.w3.org/2000/svg"}, content}
   end

   def svg(content, w, h) do
     {:svg, %{width: w, height: h, viewBox: "0 0 #{w} #{h}", xmlns: "http://www.w3.org/2000/svg"}, content}
   end

   def svg(content, w, h, sc) do
     svg({:g, %{transform: "scale(#{sc})"}, content}, w, h)
   end

   # Draws an arrow from point `a` to point `b`, with the tip being a triangle drawn at `b`.
   def arrow(a, b) do
     tip_pts = [[0, 0], [5, 0], [5, 5]]
     tip_shape = El.polygon(tip_pts)
     arrow(a, b, tip_shape)
   end

   def arrow(a, b, tip_shape) do
     {mx, my} = Tf.centroid(tip_shape)
     r = U.rad_to_deg(:math.atan2(:erlang.tl(U.vector_sub(b, a)), :erlang.hd(U.vector_sub(b, a))))
     angle_a = -315 - r
     angle_b = -135 - r

     {:g, %{},
       [
         El.line(a, b),
         U.style(Tf.translate(Tf.rotate(Tf.translate(tip_shape, {-mx, -my}), angle_a), a), %{fill: "none", stroke: "none"}),
         Tf.translate(Tf.rotate(Tf.translate(tip_shape, {-mx, -my}), angle_b), b)
       ]
     }
   end

   # Draw a text element with `text` rendered with Verdana in `font_size`.
   def label(font_size, text) do
     {:text,
       %{x: 0, y: 0, style: %{font_family: "Verdana", text_anchor: "middle", dominant_baseline: "middle", font_size: font_size}},
       text
     }
   end
end
