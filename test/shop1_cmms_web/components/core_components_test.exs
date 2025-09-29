defmodule Shop1CmmsWeb.CoreComponentsTest do
  use Shop1CmmsWeb.ConnCase
  use Phoenix.Component

  import Phoenix.LiveViewTest
  import Shop1CmmsWeb.CoreComponents

  describe "button component" do
    test "renders with different variants" do
      # Test default button
      html = render_component(&button/1, %{
        rest: %{},
        class: "",
        inner_block: [%{inner_block: fn _, _ -> "Click me" end}]
      })

      assert html =~ "Click me"
      assert html =~ "button"
    end

    test "applies custom classes" do
      html = render_component(&button/1, %{
        rest: %{},
        class: "px-2 py-1 text-xs",
        inner_block: [%{inner_block: fn _, _ -> "Small Button" end}]
      })

      assert html =~ "px-2 py-1 text-xs"
    end
  end

  describe "input component" do
    test "renders text input" do
      html = render_component(&input/1, %{
        field: %Phoenix.HTML.FormField{
          id: "test_field",
          name: "test_field",
          errors: [],
          field: :test_field,
          form: %Phoenix.HTML.Form{
            source: %{},
            impl: Phoenix.HTML.FormData.Ecto.Changeset,
            id: "test_form",
            name: "test_form",
            data: %{},
            hidden: [],
            options: []
          },
          value: ""
        },
        type: "text"
      })

      assert html =~ "input"
      assert html =~ "type=\"text\""
    end
  end

  describe "modal component" do
    test "renders modal with content" do
      assigns = %{
        id: "test-modal",
        show: true
      }

      html =
        ~H"""
        <.modal id={@id} show={@show}>
          <div>Modal content</div>
        </.modal>
        """
        |> rendered_to_string()

      assert html =~ "Modal content"
      assert html =~ "test-modal"
    end
  end

  describe "table component" do
    test "renders table with headers and rows" do
      rows = [
        %{id: 1, name: "Asset 1", status: "operational"},
        %{id: 2, name: "Asset 2", status: "down"}
      ]

      assigns = %{rows: rows}

      html =
        ~H"""
        <.table id="assets" rows={@rows}>
          <:col :let={asset} label="Name"><%= asset.name %></:col>
          <:col :let={asset} label="Status"><%= asset.status %></:col>
        </.table>
        """
        |> rendered_to_string()

      assert html =~ "Name"
      assert html =~ "Status"
      assert html =~ "Asset 1"
      assert html =~ "operational"
    end
  end

  describe "header component" do
    test "renders page header with title" do
      assigns = %{title: "Assets Management"}

      html =
        ~H"""
        <.header>
          <%= @title %>
        </.header>
        """
        |> rendered_to_string()

      assert html =~ "Assets Management"
    end
  end

  describe "flash messages" do
    test "renders flash component" do
      assigns = %{
        flash: %{"info" => "Asset created successfully"},
        kind: :info
      }

      html =
        ~H"""
        <.flash kind={@kind} flash={@flash} />
        """
        |> rendered_to_string()

      assert html =~ "Asset created successfully"
    end
  end
end
