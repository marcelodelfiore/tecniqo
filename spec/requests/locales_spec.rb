require "rails_helper"

RSpec.describe "Locale selection", type: :request do
  it "persists Brazilian Portuguese in the session" do
    patch locale_path, params: { locale: "pt-BR" }, headers: { "HTTP_REFERER" => new_session_url }
    follow_redirect!

    expect(response.body).to include("Entrar", "Enviar link de acesso")
    expect(response.body).to include('lang="pt-BR"')

    get new_session_path
    expect(response.body).to include("Informe seu e-mail")
  end

  it "supports Spanish" do
    patch locale_path, params: { locale: "es" }, headers: { "HTTP_REFERER" => new_session_url }
    follow_redirect!

    expect(response.body).to include("Iniciar sesión", "Enviar enlace de acceso")
    expect(response.body).to include('lang="es"')
  end

  it "accepts an allowlisted locale from emailed links" do
    get new_session_path(locale: "es")

    expect(response.body).to include("Iniciar sesión")

    get root_path
    expect(response.body).to include("Plataforma de ingeniería de mantenimiento")
  end

  it "preserves the locale when the session is reset" do
    patch locale_path, params: { locale: "pt-BR" }

    delete session_path
    follow_redirect!

    expect(response.body).to include("Plataforma de engenharia de manutenção")
  end

  it "ignores unsupported locales" do
    patch locale_path, params: { locale: "unsupported" }, headers: { "HTTP_REFERER" => new_session_url }
    follow_redirect!

    expect(response.body).to include("Sign in")
    expect(response.body).to include('lang="en"')
  end
end
