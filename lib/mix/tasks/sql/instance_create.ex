defmodule Mix.Tasks.Nomad.Instance.Create do
  use Mix.Task
  alias Nomad.{SQL}

  @moduledoc """
  Task for automatically creating a remote SQL database instance on a 
  pre-determined cloud provider. The instance creation is done through the 
  cloud providers' API's (mainly Amazon RDS and Google Cloud SQL) and restricted 
  to the common options and operations that are offered in those API's.

  More in depth creation of instances with other options and configurations not
  provided in here must be done in the cloud provider's console or by other
  means.
  """

  @shortdoc"""
  Create a SQL database instance on the chosen cloud provider's SQL service.
  """

  @doc """
  Runs the task for the chosen cloud provider. The shell prompts and necessary
  input parameters change with the chosen provider.
  """
  def run(args) do
    case System.get_env("PROVIDER") do 
      "AWS" -> :todo


      "GCL" -> create_instance_gcl args
    end
  end
  
  defp create_instance_aws(args) do 

  end

  defp create_instance_gcl(args) do 
    Application.ensure_all_started(:nomad_gcl)
    settings  = Map.new

    name      = Mix.Shell.IO.prompt("Insert name for the instance: ") |> String.rstrip

    region    = Mix.Shell.IO.prompt("Insert the desired region "
    <> "(asia-east1 | europe-west1 | us-central1 | us-east1):") |> String.rstrip()

    addresses = 
    if Mix.Shell.IO.yes?("Do you want to insert custom authorized IP "
      <> "addresses? (your current public IP is added automatically): ") do 
      ask_for_addresses true, []
    else 
      []
    end

    generation = 
    if Mix.Shell.IO.yes?("Do you want to use Google Cloud SQL Second Generation instances?: ") do 
      tier = Mix.Shell.IO.prompt("Insert the instance's tier ("
        <> "db-f1-micro | db-g1-small | "
        <> "db-n1-standard-1 | db-n1-standard-2 | db-n1-standard-4 | db-n1-standard-8 | db-n1-standard-1 | " 
        <> "db-n1-highmem-2 | db-n1-highmem-4 | db-n1-highmem-8 | db-n1-highmem-16): ")
      |> String.rstrip

      2
    else      
      tier = Mix.Shell.IO.prompt("Insert the instance's tier (D0 | D1 | D2 | D4 | D8 | D16 | D32): ")
      |> String.rstrip

      1
    end

    if generation == 2 do 
      size = Mix.Shell.IO.prompt("Insert the size of the data disk size (in GB) for this instance: ")
      |> String.rstrip

      # Only applicable to Second Generation instances
      settings = Map.put_new(settings, "dataDiskSizeGb", size)
    end

    username = Mix.Shell.IO.prompt("Insert the instance's root username: ") |> String.rstrip
    password = Mix.Shell.IO.prompt("Insert the instance's root password: ") |> String.rstrip

    Mix.Shell.IO.info("\n")
    Mix.Shell.IO.info("####################### SUMMARY #######################\n")

    summary = "The instance will be created with the following settings:\n"
    <> "Instance Name:        #{name}\n"
    <> "Region:               #{region}\n"
    <> "Generation:           #{generation}\n"
    <> "Tier:                 #{tier}\n"
    <> "Data Disk Size:       #{if size == nil do "Not Applicable" end}\n"
    <> "Authorized Addresses: #{print_list_with_commas(addresses, "")}"
    <> "Username:             #{username}\n"
    <> "Password:             #{password}\n"
    <> "Do you confirm?\n"

    if Mix.Shell.IO.yes?(summary) do 
      result = 
        Nomad.SQL.insert_instance name, settings, {region, tier}, {username, password}, addresses

      case result do
        :ok -> Mix.Shell.IO.info("The instance has been created successfully.")
        msg -> Mix.Shell.IO.error("A problem has occurred: \n#{msg}")
      end
    else 
      create_instance_gcl(args)
    end
  end

  defp ask_for_addresses(continue, list) do 
    if not continue do
      list 
    else
      addr = Mix.Shell.IO.prompt("Insert the address you want: ") |> String.rstrip
      res  = Mix.Shell.IO.yes? "Do you want to insert another address? "
      ask_for_addresses res, list ++ [addr]
    end
  end

  defp print_list_with_commas([], _), do: "Not Applicable\n"
  defp print_list_with_commas([head | []], string), do: string <> head <> "\n"
  defp print_list_with_commas([head | tail], string) do 
    print_list_with_commas tail, string <> head <> ", "
  end
end