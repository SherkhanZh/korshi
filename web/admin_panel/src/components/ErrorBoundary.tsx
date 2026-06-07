import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
}
interface State {
  error: Error | null;
}

/** Catches render/runtime errors so one broken screen can't freeze the panel. */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // eslint-disable-next-line no-console
    console.error('Panel error:', error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      return (
        <div className="flex h-full min-h-screen flex-col items-center justify-center gap-3 bg-cream p-8 text-center">
          <h1 className="text-lg font-bold">Что-то пошло не так</h1>
          <p className="max-w-md text-sm text-ink2">
            Произошла ошибка в интерфейсе. Перезагрузите страницу — данные не потеряны.
          </p>
          <button className="btn-primary mt-2" onClick={() => window.location.reload()}>
            Перезагрузить
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
