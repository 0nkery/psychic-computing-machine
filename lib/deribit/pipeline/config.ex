defmodule Deribit.Pipeline.Config do
  def api_url do
    Application.get_env(:deribit, :api_url)
  end

  def pair do
    Application.get_env(:deribit, :pair)
  end
end
