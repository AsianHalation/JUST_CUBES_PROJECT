(function () {
    const toast = document.getElementById("toast");
    if (!toast) return;
    window.showToast = function (message) {
        toast.textContent = message;
        toast.classList.add("show");
        clearTimeout(window._toastTimer);
        window._toastTimer = setTimeout(() => toast.classList.remove("show"), 3000);
    };
})();

document.querySelectorAll(".payment-option").forEach(option => {
    option.addEventListener("click", () => {
        document.querySelectorAll(".payment-option").forEach(o => o.classList.remove("selected"));
        option.classList.add("selected");
    });
});
