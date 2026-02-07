# ProFile AUX (Flutter) — pronto para copiar/colar

Este ZIP contém **apenas** os arquivos do app (source).
No Windows, você cria o projeto com `flutter create` e **substitui** os arquivos pelos do ZIP.

## 1) Criar projeto (Windows)
Entre na pasta que você quer (ex.:):
`C:\Users\zinod\OneDrive\Desktop\ProFileIPA`

Rode:
```
flutter create profile_aux
cd profile_aux
```

## 2) Copiar e colar (substituir)
Copie do ZIP para dentro do projeto:
- `lib/main.dart`
- `pubspec.yaml`

## 3) Rodar no Windows
Dentro da pasta do projeto:
```
flutter pub get
flutter run -d windows
```

## 4) iOS Shortcuts (para os botões)
Crie no iPhone dois atalhos com nomes exatos:
- `Abrir Free Fire`
- `Abrir Free Fire Max`

Cada atalho deve ter a ação:
**Abrir App** -> (Free Fire / Free Fire MAX)

O app chama:
`shortcuts://run-shortcut?name=<NOME>`

## 5) Login
- Tenta FaceID/TouchID se disponível.
- PIN fallback: `ProFileLITE` (aceita também `ProFile`).

## 6) Preferências salvas (Keychain)
Preferências são salvas via `flutter_secure_storage`:
- hudPro, fpsOpt, sens, fov, aux, modo, lastApply
