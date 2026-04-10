# Verification

## Policy

- Flutter UI or Dart changes: run at least `flutter analyze` in `front/`.
- Backend Python changes: run the narrowest executable validation available for the touched path.
- Cross-cutting domain changes: verify both frontend and backend if the concept is duplicated.
- If a change touches Korean strings, API payload text, logs, or localized UI copy, include a quick encoding sanity check.

## Commands

### Frontend

- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Web run: `flutter run -d chrome`

Run frontend commands from `front/`.

### Backend

- Install deps: `.\venv\Scripts\python -m pip install -r requirements.txt`
- Run API locally: `.\venv\Scripts\python -m uvicorn main:app --reload`
- Ad hoc script run: `.\venv\Scripts\python <script>.py`

Run backend commands from `back/`.
