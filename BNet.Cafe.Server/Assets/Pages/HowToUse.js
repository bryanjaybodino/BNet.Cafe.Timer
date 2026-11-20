(function () {
    // Supports full YouTube URLs, YouTube video IDs, or Facebook URLs (facebook.com / fb.watch)
    const HOW_TO_USE_DATA = [
        {
            title: "System Overview",
            url: "https://www.youtube.com/watch?v=pX9K1vA3Kg8",
            notes: "Short Introduction of BNet Cafe Timer"
        },
        {
            title: "TAGALOG - BNet Cafe Timer Setup Tutorial",
            url: "https://www.youtube.com/watch?v=uLtFC5AaoX0",
            notes: "Installation Guide"
        },
        {
            title: "TAGALOG - BNet Cafe Timer Online Forwarder - FREE 100%",
            url: "https://www.youtube.com/watch?v=8S-PL1pyA2g",
            notes: "Access your comshop anywhere"
        },
        {
            title: "TAGALOG - BNet Cafe Patcher Tutorial",
            url: "https://www.youtube.com/watch?v=GJ6lmyOQl1c",
            notes: "Update BNet Cafe using patcher or you use [Global Patcher Command] on the Maintenance page"
        },
        {
            title: "TAGALOG - BNet Cafe Game Menu Tutorial",
            url: "https://www.youtube.com/watch?v=fdFyozXMbss",
            notes: "Light Weight Game Menu integrated to BNet Timer it can track the most popular application on your shop"
        },
        {
            title: "TAGALOG - BNet Cafe Admin Control Tutorial",
            url: "https://www.youtube.com/watch?v=d8E_uMjoRSw",
            notes: "How to use client admin control"
        },
        {
            title: "KIOSK Centralized Coinslot - WITH MONITOR",
            url: "https://www.facebook.com/reel/1356232633059146",
            notes: "How to use kiosk using with monitor"
        },
        {
            title: "KIOSK Centralized Coinslot - WITHOUT MONITOR",
            url: "https://www.facebook.com/reel/1600705268751779",
            notes: "How to use kiosk using without monitor"
        }
    ];

    const PAGE_SIZE = 10;
    let currentPage = 1;
    let searchQuery = "";

    function escapeHtml(str) {
        return String(str ?? "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function normalizeTutorialUrl(rawUrl) {
        const trimmed = String(rawUrl ?? "").trim();
        if (!trimmed) return "";
        if (/^https?:\/\//i.test(trimmed)) {
            return trimmed;
        }
        return `https://www.youtube.com/watch?v=${encodeURIComponent(trimmed)}`;
    }

    function isSafeHttpUrl(url) {
        return /^https?:\/\//i.test(url);
    }

    function getPlatformMeta(url) {
        const lower = String(url ?? "").toLowerCase();

        if (lower.includes("facebook.com") || lower.includes("fb.watch") || lower.includes("fb.com")) {
            return {
                provider: "facebook",
                badge: "Facebook",
                iconClass: "fab fa-facebook",
                actionText: "Watch on Facebook"
            };
        }

        if (lower.includes("youtube.com") || lower.includes("youtu.be")) {
            return {
                provider: "youtube",
                badge: "YouTube",
                iconClass: "fab fa-youtube",
                actionText: "Watch Tutorial"
            };
        }

        return {
            provider: "web",
            badge: "Link",
            iconClass: "fas fa-external-link-alt",
            actionText: "Open Guide"
        };
    }

    function getValidItems() {
        return HOW_TO_USE_DATA.filter(item => {
            const title = String(item.title ?? "").trim();
            const url = String(item.url ?? "").trim();
            const notes = String(item.notes ?? "").trim();
            return Boolean(title || url || notes);
        });
    }

    function getFilteredData() {
        const validItems = getValidItems();
        const q = searchQuery.trim().toLowerCase();
        if (!q) return validItems;

        return validItems.filter(item => {
            const title = String(item.title ?? "").toLowerCase();
            const url = normalizeTutorialUrl(item.url).toLowerCase();
            const notes = String(item.notes ?? "").toLowerCase();
            const meta = getPlatformMeta(url);
            return (
                title.includes(q) ||
                url.includes(q) ||
                notes.includes(q) ||
                meta.badge.toLowerCase().includes(q)
            );
        });
    }

    function renderHowToUse() {
        const tbody = document.getElementById("htuTableBody");
        const prevBtn = document.getElementById("htuPrevBtn");
        const nextBtn = document.getElementById("htuNextBtn");
        const prevItem = document.getElementById("htuPrevItem");
        const nextItem = document.getElementById("htuNextItem");
        const currentIndexEl = document.getElementById("htuCurrentIndex");

        if (!tbody || !prevBtn || !nextBtn || !currentIndexEl) return;

        const filtered = getFilteredData();
        const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));

        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;

        const startIndex = (currentPage - 1) * PAGE_SIZE;
        const pageItems = filtered.slice(startIndex, startIndex + PAGE_SIZE);

        if (pageItems.length === 0) {
            tbody.innerHTML = `<tr><td colspan="3" class="htu-empty-cell"><i class="fas fa-video-slash"></i> No matching tutorial videos found.</td></tr>`;
        } else {
            tbody.innerHTML = pageItems.map(item => {
                const safeTitle = escapeHtml(item.title);
                const resolvedUrl = normalizeTutorialUrl(item.url);
                const safeHref = isSafeHttpUrl(resolvedUrl) ? escapeHtml(resolvedUrl) : "#";
                const safeNotes = escapeHtml(item.notes);
                const meta = getPlatformMeta(resolvedUrl);

                return `
                    <tr>
                        <td><span class="htu-topic-title">${safeTitle}</span></td>
                        <td>
                            <a href="${safeHref}" class="htu-yt-link htu-link--${meta.provider}" target="_blank" rel="noopener noreferrer">
                                <i class="${meta.iconClass}"></i>
                                <span>${escapeHtml(meta.actionText)}</span>
                                <span class="htu-yt-badge htu-badge--${meta.provider}">${escapeHtml(meta.badge)}</span>
                            </a>
                            <span class="htu-yt-url-sub">${escapeHtml(resolvedUrl)}</span>
                        </td>
                        <td><span class="htu-notes-text">${safeNotes}</span></td>
                    </tr>
                `;
            }).join("");
        }

        const isFirstPage = currentPage <= 1;
        const isLastPage = currentPage >= totalPages;

        currentIndexEl.textContent = String(currentPage);
        prevBtn.disabled = isFirstPage;
        nextBtn.disabled = isLastPage;

        if (prevItem) prevItem.classList.toggle("disabled", isFirstPage);
        if (nextItem) nextItem.classList.toggle("disabled", isLastPage);
    }

    function initHowToUse() {
        const searchInput = document.getElementById("htuSearchInput");
        const prevBtn = document.getElementById("htuPrevBtn");
        const nextBtn = document.getElementById("htuNextBtn");

        if (!searchInput || !prevBtn || !nextBtn) return;

        searchInput.addEventListener("input", function () {
            searchQuery = this.value || "";
            currentPage = 1;
            renderHowToUse();
        });

        prevBtn.addEventListener("click", function () {
            if (currentPage > 1) {
                currentPage--;
                renderHowToUse();
            }
        });

        nextBtn.addEventListener("click", function () {
            const totalPages = Math.max(1, Math.ceil(getFilteredData().length / PAGE_SIZE));
            if (currentPage < totalPages) {
                currentPage++;
                renderHowToUse();
            }
        });

        renderHowToUse();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initHowToUse);
    } else {
        initHowToUse();
    }
})();