import { reactive } from 'vue';

const state = reactive({
  show: false,
  type: 'info',
  title: '',
  message: '',
  duration: 0,
  actionLabel: '',
  onAction: null,
});

let queue = [];
let processing = false;

export function useDynamicIsland() {
  function notify({ type = 'info', title, message = '', duration = 0, actionLabel = '', onAction = null } = {}) {
    const item = { type, title, message, duration, actionLabel, onAction };

    if (processing) {
      queue.push(item);
      return;
    }

    show(item);
  }

  function show(item) {
    processing = true;
    Object.assign(state, {
      show: true,
      type: item.type,
      title: item.title,
      message: item.message,
      duration: item.duration,
      actionLabel: item.actionLabel,
      onAction: item.onAction,
    });
  }

  function dismiss() {
    state.show = false;
    processing = false;

    // Show next in queue after a short delay
    if (queue.length > 0) {
      setTimeout(() => show(queue.shift()), 400);
    }
  }

  function handleAction() {
    if (state.onAction) state.onAction();
    dismiss();
  }

  return {
    islandState: state,
    notify,
    dismiss,
    handleAction,
  };
}
