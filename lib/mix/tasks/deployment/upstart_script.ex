defmodule Nomad.UpstartScript do
  @behaviour Script

  @moduledoc """
  Builds and deletes the Upstart script for the production release.
  """

  @doc """
  Builds the script for the Upstart of the production release of the application.
  The script follows the Phoenix Official EXRM Releases Guide.
  """
  def build_script do 
    {:ok, script} = File.open "#{System.get_env("APP_NAME")}.conf", [:write]

    :ok = IO.binwrite script, bs
    File.close script    
  end

  defp bs do 
    """
    description "#{System.get_env("APP_NAME")}"

    ## Uncomment the following two lines to run the
    ## application as www-data:www-data
    #setuid www-data
    #setgid www-data

    start on runlevel [2345]
    stop on runlevel [016]

    expect stop
    respawn

    env MIX_ENV=prod
    export MIX_ENV

    ## Uncomment the following two lines if we configured
    ## our port with an environment variable.
    #env PORT=#{System.get_env("PORT")}
    #export PORT

    ## Add app HOME directory.
    env HOME=/app
    export HOME


    pre-start exec /bin/sh /app/bin/#{System.get_env("APP_NAME")} start

    post-stop exec /bin/sh /app/bin/#{System.get_env("APP_NAME")} stop
    """
  end

  @doc """
  Deletes the Upstart script from the local directory.
  """
  def delete_script do 
    File.rm "#{System.get_env("APP_NAME")}.conf"
  end
end