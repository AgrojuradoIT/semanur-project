import { ref, watch } from 'vue';

const refreshTrigger = ref(0);

export function useRefresh() {
    function triggerRefresh() {
        refreshTrigger.value++;
    }

    function onRefresh(callback) {
        watch(refreshTrigger, (newVal) => {
            if (newVal > 0) callback();
        });
    }

    return {
        refreshTrigger,
        triggerRefresh,
        onRefresh,
    };
}

