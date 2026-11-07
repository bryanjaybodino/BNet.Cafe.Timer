class BNetDropdown {
    constructor(target) {
        // Find existing DOM element by ID or CSS selector
        const el = typeof target === 'string' ? document.querySelector(target) : target;

        if (!el) {
            console.error(`BNetDropdown: Element "${target}" not found.`);
            return;
        }

        // Reuse the instance if this element was already initialized
        if (el._bnetDropdown) {
            return el._bnetDropdown;
        }

        this.dropdown = el;
        this.dropdown._bnetDropdown = this;
        this.toggleBtn = el.querySelector('.bnet-dropdown-toggle');
        this.menu = el.querySelector('.bnet-dropdown-menu');
        this.gap = 4;

        this.initDOM();
    }

    initDOM() {
        // Ensure dropdown has correct base class
        if (!this.dropdown.classList.contains('bnet-dropdown')) {
            this.dropdown.classList.add('bnet-dropdown');
        }

        // Prevent <button> toggles from submitting the ASP.NET form
        if (this.toggleBtn && this.toggleBtn.tagName === 'BUTTON' && !this.toggleBtn.getAttribute('type')) {
            this.toggleBtn.setAttribute('type', 'button');
        }
    }

    isOpen() {
        return this.dropdown.classList.contains('open');
    }

    open() {
        if (!this.menu || !this.toggleBtn) return;

        // Only one dropdown open at a time
        BNetDropdown.closeAll(this);

        // Show first so the menu can be measured
        this.dropdown.classList.add('open');
        BNetDropdown.current = this;
        this.position();
    }

    close() {
        this.dropdown.classList.remove('open');
        if (BNetDropdown.current === this) {
            BNetDropdown.current = null;
        }
    }

    toggle() {
        this.isOpen() ? this.close() : this.open();
    }

    position() {
        // Dropdown was removed from the page (e.g. UpdatePanel re-render)
        if (!this.dropdown.isConnected) {
            this.close();
            return;
        }
        if (!this.isOpen()) return;

        const t = this.toggleBtn.getBoundingClientRect();
        const m = this.menu.getBoundingClientRect();

        // Vertical: below the button, or above if it doesn't fit
        let top = t.bottom + this.gap;
        if (top + m.height > window.innerHeight && t.top - m.height - this.gap > 0) {
            top = t.top - m.height - this.gap;
        }

        // Horizontal: align to the button's left, keep inside the viewport
        let left = t.left;
        if (left + m.width > window.innerWidth - 8) {
            left = Math.max(8, t.right - m.width);
        }

        this.menu.style.top = top + 'px';
        this.menu.style.left = left + 'px';
    }

    // Close every open dropdown (optionally except one)
    static closeAll(except = null) {
        document.querySelectorAll('.bnet-dropdown.open').forEach((el) => {
            if (except && el === except.dropdown) return;
            new BNetDropdown(el).close();
        });
        if (!except) BNetDropdown.current = null;
    }

    // Static initializer: ONE delegated handler for every .bnet-dropdown,
    // including rows rendered later (UpdatePanel / GridView postbacks)
    static initAutoBind() {
        document.addEventListener('click', (e) => {
            const dd = e.target.closest('.bnet-dropdown');

            // Click outside any dropdown
            if (!dd) {
                BNetDropdown.closeAll();
                return;
            }

            const instance = new BNetDropdown(dd);   // creates or reuses

            if (e.target.closest('.bnet-dropdown-toggle')) {
                e.preventDefault();
                instance.toggle();
            } else if (e.target.closest('.bnet-dropdown-menu')) {
                // Item click: close, its own click/postback still runs
                instance.close();
            }
        });

        // Follow the button while scrolling (page, table, or any scrollable parent)
        let ticking = false;
        const onMove = () => {
            if (!BNetDropdown.current || ticking) return;
            ticking = true;
            requestAnimationFrame(() => {
                ticking = false;
                if (BNetDropdown.current) BNetDropdown.current.position();
            });
        };

        window.addEventListener('scroll', onMove, true); // true = also catches the table's own scroll
        window.addEventListener('resize', onMove);

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') BNetDropdown.closeAll();
        });
    }
}

BNetDropdown.current = null;

// Auto-bind globally on DOM load
document.addEventListener('DOMContentLoaded', () => {
    BNetDropdown.initAutoBind();
});