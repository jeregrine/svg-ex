defmodule SVGTest do
  use ExUnit.Case
  alias SVG.Elements, as: El

  doctest SVG
  doctest SVG.Utils
  doctest SVG.Composites


  def assert_renders({tag, props}) do
    str = SVG.Tools.render({tag, props})

    assert str =~ to_string(tag)
    for {key, val} <- props do
      assert str =~ "#{key}=\"#{val}\""
    end
  end
  test "renders a svg" do
    assert_renders El.circle(10)
    assert_renders El.rect(10, 10)
  end

end
