let isEditMode = false;
let zoomLevel = 1.0;
let selectedSeats = new Set();

// History Stacks
const undoStack = [];
const redoStack = [];

// DOM References
let floorContainer, viewport, selectionBox, guideVLine, guideHLine, btnUndo, btnRedo;

function initMapElements() {
    floorContainer = document.getElementById('floorPlanContainer');
    viewport = document.getElementById('floorPlanViewport');
    selectionBox = document.getElementById('selectionBox');
    guideVLine = document.getElementById('guideVLine');
    guideHLine = document.getElementById('guideHLine');
    btnUndo = document.getElementById('btnUndo');
    btnRedo = document.getElementById('btnRedo');

    if (!floorContainer || !viewport) return;

    // Detect mobile screen width (e.g., 768px or lower) and set initial zoom to 50%
    if (window.innerWidth <= 768) {
        zoomLevel = 0.5;
    } else {
        zoomLevel = 1.0;
    }

    floorContainer.classList.toggle('edit-mode', isEditMode);

    // Apply visual edit mode styles if edit mode was active prior to postback
    if (isEditMode) {
        const seats = document.querySelectorAll('.seat-card');
        seats.forEach(s => s.classList.add('edit-mode'));
        const btn = document.getElementById('btnEditMode');
        if (btn) {
            btn.classList.replace('btn-secondary', 'btn-danger');
            btn.innerHTML = '<i class="fa-solid fa-xmark"></i> Lock Drag & Drop';
        }
    }

    applyZoom();
    bindEvents();
    updateHistoryUI();
}

// Handle Page / UpdatePanel Lifecycle
document.addEventListener('DOMContentLoaded', function () {
    initMapElements();
});

if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        initMapElements();
    });
}

// ==========================================
// 1. UNDO / REDO SYSTEM
// ==========================================
function getCanvasState() {
    const state = [];
    document.querySelectorAll('.seat-card').forEach(seat => {
        state.push({
            id: seat.getAttribute('data-id'),
            left: seat.style.left,
            top: seat.style.top
        });
    });
    return state;
}

function saveState() {
    undoStack.push(getCanvasState());
    redoStack.length = 0; // Clear redo history on new action
    updateHistoryUI();
}

function applyState(state) {
    state.forEach(item => {
        const seat = document.querySelector(`.seat-card[data-id="${item.id}"]`);
        if (seat) {
            seat.style.left = item.left;
            seat.style.top = item.top;
        }
    });
}

function undo() {
    if (undoStack.length === 0 || !isEditMode) return;

    redoStack.push(getCanvasState());
    const previousState = undoStack.pop();
    applyState(previousState);
    updateHistoryUI();
}

function redo() {
    if (redoStack.length === 0 || !isEditMode) return;

    undoStack.push(getCanvasState());
    const nextState = redoStack.pop();
    applyState(nextState);
    updateHistoryUI();
}

function updateHistoryUI() {
    if (btnUndo) btnUndo.disabled = undoStack.length === 0 || !isEditMode;
    if (btnRedo) btnRedo.disabled = redoStack.length === 0 || !isEditMode;
}

// Keyboard Shortcuts for Undo/Redo
document.addEventListener('keydown', function (e) {
    if (!isEditMode) return;

    if (e.ctrlKey || e.metaKey) {
        if (e.key.toLowerCase() === 'z') {
            if (e.shiftKey) {
                redo();
            } else {
                undo();
            }
            e.preventDefault();
        } else if (e.key.toLowerCase() === 'y') {
            redo();
            e.preventDefault();
        }
    }
});

// ==========================================
// 2. ZOOM CONTROLS
// ==========================================
function adjustZoom(delta) {
    zoomLevel = Math.min(Math.max(0.4, zoomLevel + delta), 2.0);
    applyZoom();
}

function resetZoom() {
    if (window.innerWidth <= 768) {
        zoomLevel = 0.5;
    } else {
        zoomLevel = 1.0;
    }
    applyZoom();
}

function applyZoom() {
    if (!viewport) return;
    viewport.style.transform = `scale(${zoomLevel})`;
    const zoomText = document.getElementById('zoomText');
    if (zoomText) zoomText.innerText = `${Math.round(zoomLevel * 100)}%`;
}

function handleWheelZoom(e) {
    if (e.ctrlKey) {
        e.preventDefault();
        adjustZoom(e.deltaY < 0 ? 0.1 : -0.1);
    }
}

// Pinch-to-zoom (touch)
let pinchStartDist = 0;
let pinchStartZoom = 1;

function getTouchDist(t) {
    return Math.hypot(t[0].clientX - t[1].clientX, t[0].clientY - t[1].clientY);
}

function handlePinchStart(e) {
    if (e.touches.length === 2) {
        pinchStartDist = getTouchDist(e.touches);
        pinchStartZoom = zoomLevel;
    }
}

function handlePinchMove(e) {
    if (e.touches.length !== 2 || !pinchStartDist) return;
    if (e.cancelable) e.preventDefault();

    const rect = floorContainer.getBoundingClientRect();
    const mx = (e.touches[0].clientX + e.touches[1].clientX) / 2 - rect.left;
    const my = (e.touches[0].clientY + e.touches[1].clientY) / 2 - rect.top;

    // Canvas point currently under the fingers
    const contentX = (floorContainer.scrollLeft + mx) / zoomLevel;
    const contentY = (floorContainer.scrollTop + my) / zoomLevel;

    const newZoom = pinchStartZoom * (getTouchDist(e.touches) / pinchStartDist);
    zoomLevel = Math.min(Math.max(0.4, newZoom), 2.0);
    applyZoom();

    // Keep that point under the fingers
    floorContainer.scrollLeft = contentX * zoomLevel - mx;
    floorContainer.scrollTop = contentY * zoomLevel - my;
}

function handlePinchEnd(e) {
    if (e.touches.length < 2) pinchStartDist = 0;
}

// ==========================================
// 3. TOGGLE EDIT MODE
// ==========================================
function toggleEditMode() {
    isEditMode = !isEditMode;
    const btn = document.getElementById('btnEditMode');
    const saveBtn = document.getElementById('Button_SaveLayout');
    const seats = document.querySelectorAll('.seat-card');

    clearSelection();
    if (floorContainer) floorContainer.classList.toggle('edit-mode', isEditMode);

    if (isEditMode) {
        if (btn) {
            btn.classList.replace('btn-secondary', 'btn-danger');
            btn.innerHTML = '<i class="fa-solid fa-xmark"></i> Lock Drag & Drop';
        }
        if (saveBtn) saveBtn.classList.remove('d-none');
        seats.forEach(s => s.classList.add('edit-mode'));
    } else {
        if (btn) {
            btn.classList.replace('btn-danger', 'btn-secondary');
            btn.innerHTML = '<i class="fa-solid fa-arrows-up-down-left-right"></i> Enable Drag & Drop';
        }
        if (saveBtn) saveBtn.classList.add('d-none');
        seats.forEach(s => s.classList.remove('edit-mode'));
    }

    updateHistoryUI();
}

// ==========================================
// 4. EVENT BINDING & INTERACTION ENGINE
// ==========================================
function clearSelection() {
    selectedSeats.forEach(seat => seat.classList.remove('selected'));
    selectedSeats.clear();
}

function hideGuides() {
    if (guideVLine) guideVLine.style.display = 'none';
    if (guideHLine) guideHLine.style.display = 'none';
}

function bindEvents() {
    if (floorContainer) {
        floorContainer.removeEventListener('wheel', handleWheelZoom);
        floorContainer.addEventListener('wheel', handleWheelZoom, { passive: false });

        // Pinch-to-zoom bindings for mobile
        floorContainer.removeEventListener('touchstart', handlePinchStart);
        floorContainer.removeEventListener('touchmove', handlePinchMove);
        floorContainer.removeEventListener('touchend', handlePinchEnd);
        floorContainer.addEventListener('touchstart', handlePinchStart, { passive: true });
        floorContainer.addEventListener('touchmove', handlePinchMove, { passive: false });
        floorContainer.addEventListener('touchend', handlePinchEnd, { passive: true });
    }

    if (viewport) {
        viewport.removeEventListener('mousedown', handleMouseDown);
        viewport.addEventListener('mousedown', handleMouseDown);

        // Touch event bindings for mobile
        viewport.removeEventListener('touchstart', handleTouchStart);
        viewport.addEventListener('touchstart', handleTouchStart, { passive: false });
    }
}
function handleTouchStart(e) {
    if (!isEditMode) return;

    // Multi-touch (pinch): let the browser / pinch handler deal with it
    if (e.touches.length !== 1) return;

    const touch = e.touches[0];
    const targetSeat = touch.target.closest('.seat-card');

    // Empty space: let the browser pan/scroll the canvas natively
    if (!targetSeat) {
        clearSelection();
        return;
    }

    // Only block scrolling when dragging a seat
    if (e.cancelable) e.preventDefault();

    if (!selectedSeats.has(targetSeat)) {
        clearSelection();
        targetSeat.classList.add('selected');
        selectedSeats.add(targetSeat);
    }

    saveState();

    const startTouchX = touch.clientX;
    const startTouchY = touch.clientY;

    const initialPositions = new Map();
    selectedSeats.forEach(seat => {
        initialPositions.set(seat, {
            left: seat.offsetLeft,
            top: seat.offsetTop
        });
    });

    const otherSeats = Array.from(document.querySelectorAll('.seat-card')).filter(s => !selectedSeats.has(s));

    function onTouchMove(e) {
        if (e.cancelable) e.preventDefault();
        if (e.touches.length !== 1) return;

        const currentTouch = e.touches[0];
        const deltaX = (currentTouch.clientX - startTouchX) / zoomLevel;
        const deltaY = (currentTouch.clientY - startTouchY) / zoomLevel;

        let snapDx = 0;
        let snapDy = 0;
        let showV = false;
        let showH = false;
        let vLinePos = 0;
        let hLinePos = 0;

        const primarySeat = targetSeat;
        const primaryInit = initialPositions.get(primarySeat);
        let rawLeft = primaryInit.left + deltaX;
        let rawTop = primaryInit.top + deltaY;

        const snapThreshold = 6;
        const pWidth = primarySeat.offsetWidth;
        const pHeight = primarySeat.offsetHeight;

        for (const other of otherSeats) {
            const oLeft = other.offsetLeft;
            const oTop = other.offsetTop;
            const oRight = oLeft + other.offsetWidth;
            const oBottom = oTop + other.offsetHeight;

            // Vertical Alignment
            if (Math.abs(rawLeft - oLeft) < snapThreshold) {
                snapDx = oLeft - rawLeft;
                showV = true; vLinePos = oLeft;
            } else if (Math.abs(rawLeft + pWidth - oRight) < snapThreshold) {
                snapDx = oRight - pWidth - rawLeft;
                showV = true; vLinePos = oRight;
            }

            // Horizontal Alignment
            if (Math.abs(rawTop - oTop) < snapThreshold) {
                snapDy = oTop - rawTop;
                showH = true; hLinePos = oTop;
            } else if (Math.abs(rawTop + pHeight - oBottom) < snapThreshold) {
                snapDy = oBottom - pHeight - rawTop;
                showH = true; hLinePos = oBottom;
            }
        }

        // Snap Guides
        if (showV) {
            guideVLine.style.left = `${vLinePos}px`;
            guideVLine.style.display = 'block';
        } else {
            guideVLine.style.display = 'none';
        }

        if (showH) {
            guideHLine.style.top = `${hLinePos}px`;
            guideHLine.style.display = 'block';
        } else {
            guideHLine.style.display = 'none';
        }

        // Apply updated positions
        selectedSeats.forEach(seat => {
            const init = initialPositions.get(seat);
            let newLeft = Math.max(0, init.left + deltaX + snapDx);
            let newTop = Math.max(0, init.top + deltaY + snapDy);

            if (!showV) newLeft = Math.round(newLeft / 10) * 10;
            if (!showH) newTop = Math.round(newTop / 10) * 10;

            seat.style.left = `${newLeft}px`;
            seat.style.top = `${newTop}px`;
        });
    }

    function onTouchEnd() {
        hideGuides();
        document.removeEventListener('touchmove', onTouchMove);
        document.removeEventListener('touchend', onTouchEnd);
        document.removeEventListener('touchcancel', onTouchEnd);
    }

    document.addEventListener('touchmove', onTouchMove, { passive: false });
    document.addEventListener('touchend', onTouchEnd);
    document.addEventListener('touchcancel', onTouchEnd);
}

// Drag-to-pan with the mouse (scrollbars are hidden)
function startMousePan(e) {
    e.preventDefault(); // also blocks middle-click autoscroll

    const startX = e.clientX;
    const startY = e.clientY;
    const startLeft = floorContainer.scrollLeft;
    const startTop = floorContainer.scrollTop;

    floorContainer.classList.add('panning');

    function onPanMove(ev) {
        floorContainer.scrollLeft = startLeft - (ev.clientX - startX);
        floorContainer.scrollTop = startTop - (ev.clientY - startY);
    }

    function onPanEnd() {
        floorContainer.classList.remove('panning');
        document.removeEventListener('mousemove', onPanMove);
        document.removeEventListener('mouseup', onPanEnd);
    }

    document.addEventListener('mousemove', onPanMove);
    document.addEventListener('mouseup', onPanEnd);
}

function handleMouseDown(e) {
    const targetSeat = e.target.closest('.seat-card');

    // Pan: left-drag on empty space (view mode) or middle mouse button (any mode)
    if (e.button === 1 || (!isEditMode && !targetSeat && e.button === 0)) {
        startMousePan(e);
        return;
    }

    if (!isEditMode) return;
    if (e.button !== 0) return; // edit mode: left button only

    // Clicked on empty space: Start Selection Box
    if (!targetSeat) {
        if (!e.ctrlKey && !e.shiftKey) clearSelection();

        const rect = viewport.getBoundingClientRect();
        const startX = (e.clientX - rect.left) / zoomLevel;
        const startY = (e.clientY - rect.top) / zoomLevel;

        selectionBox.style.left = `${startX}px`;
        selectionBox.style.top = `${startY}px`;
        selectionBox.style.width = '0px';
        selectionBox.style.height = '0px';
        selectionBox.style.display = 'block';

        function onMouseMove(e) {
            const currentX = (e.clientX - rect.left) / zoomLevel;
            const currentY = (e.clientY - rect.top) / zoomLevel;

            const left = Math.min(startX, currentX);
            const top = Math.min(startY, currentY);
            const width = Math.abs(currentX - startX);
            const height = Math.abs(currentY - startY);

            selectionBox.style.left = `${left}px`;
            selectionBox.style.top = `${top}px`;
            selectionBox.style.width = `${width}px`;
            selectionBox.style.height = `${height}px`;

            // Calculate intersections
            document.querySelectorAll('.seat-card').forEach(seat => {
                const sLeft = seat.offsetLeft;
                const sTop = seat.offsetTop;
                const sRight = sLeft + seat.offsetWidth;
                const sBottom = sTop + seat.offsetHeight;

                if (sLeft < left + width && sRight > left && sTop < top + height && sBottom > top) {
                    seat.classList.add('selected');
                    selectedSeats.add(seat);
                } else if (!e.ctrlKey) {
                    seat.classList.remove('selected');
                    selectedSeats.delete(seat);
                }
            });
        }

        function onMouseUp() {
            selectionBox.style.display = 'none';
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        }

        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup', onMouseUp);
        return;
    }

    // Clicked on a Seat: Toggle or Move Selection Group
    if (e.ctrlKey || e.shiftKey) {
        if (selectedSeats.has(targetSeat)) {
            targetSeat.classList.remove('selected');
            selectedSeats.delete(targetSeat);
        } else {
            targetSeat.classList.add('selected');
            selectedSeats.add(targetSeat);
        }
    } else {
        if (!selectedSeats.has(targetSeat)) {
            clearSelection();
            targetSeat.classList.add('selected');
            selectedSeats.add(targetSeat);
        }
    }

    // Snapshot state before dragging starts (for Undo)
    saveState();

    const startMouseX = e.clientX;
    const startMouseY = e.clientY;

    const initialPositions = new Map();
    selectedSeats.forEach(seat => {
        initialPositions.set(seat, {
            left: seat.offsetLeft,
            top: seat.offsetTop
        });
    });

    // Collect alignment targets (unselected seats)
    const otherSeats = Array.from(document.querySelectorAll('.seat-card')).filter(s => !selectedSeats.has(s));

    function onDragMove(e) {
        const deltaX = (e.clientX - startMouseX) / zoomLevel;
        const deltaY = (e.clientY - startMouseY) / zoomLevel;

        let snapDx = 0;
        let snapDy = 0;
        let showV = false;
        let showH = false;
        let vLinePos = 0;
        let hLinePos = 0;

        const primarySeat = targetSeat;
        const primaryInit = initialPositions.get(primarySeat);
        let rawLeft = primaryInit.left + deltaX;
        let rawTop = primaryInit.top + deltaY;

        // Alignment Snap Checks (Threshold 6px)
        const snapThreshold = 6;
        const pWidth = primarySeat.offsetWidth;
        const pHeight = primarySeat.offsetHeight;

        for (const other of otherSeats) {
            const oLeft = other.offsetLeft;
            const oTop = other.offsetTop;
            const oRight = oLeft + other.offsetWidth;
            const oBottom = oTop + other.offsetHeight;

            // Vertical Alignment (X-Axis)
            if (Math.abs(rawLeft - oLeft) < snapThreshold) {
                snapDx = oLeft - rawLeft;
                showV = true; vLinePos = oLeft;
            } else if (Math.abs(rawLeft + pWidth - oRight) < snapThreshold) {
                snapDx = oRight - pWidth - rawLeft;
                showV = true; vLinePos = oRight;
            }

            // Horizontal Alignment (Y-Axis)
            if (Math.abs(rawTop - oTop) < snapThreshold) {
                snapDy = oTop - rawTop;
                showH = true; hLinePos = oTop;
            } else if (Math.abs(rawTop + pHeight - oBottom) < snapThreshold) {
                snapDy = oBottom - pHeight - rawTop;
                showH = true; hLinePos = oBottom;
            }
        }

        // Draw Snap Lines
        if (showV) {
            guideVLine.style.left = `${vLinePos}px`;
            guideVLine.style.display = 'block';
        } else {
            guideVLine.style.display = 'none';
        }

        if (showH) {
            guideHLine.style.top = `${hLinePos}px`;
            guideHLine.style.display = 'block';
        } else {
            guideHLine.style.display = 'none';
        }

        // Apply calculated positions to whole selection
        selectedSeats.forEach(seat => {
            const init = initialPositions.get(seat);
            let newLeft = Math.max(0, init.left + deltaX + snapDx);
            let newTop = Math.max(0, init.top + deltaY + snapDy);

            // Snap to 10px grid if not snapping to alignment lines
            if (!showV) newLeft = Math.round(newLeft / 10) * 10;
            if (!showH) newTop = Math.round(newTop / 10) * 10;

            seat.style.left = `${newLeft}px`;
            seat.style.top = `${newTop}px`;
        });
    }

    function onDragEnd() {
        hideGuides();
        document.removeEventListener('mousemove', onDragMove);
        document.removeEventListener('mouseup', onDragEnd);
    }

    document.addEventListener('mousemove', onDragMove);
    document.addEventListener('mouseup', onDragEnd);
}

// ==========================================
// 5. PREPARE PAYLOAD FOR SERVER
// ==========================================
function prepareLayoutSave() {
    const seats = document.querySelectorAll('.seat-card');
    const positions = [];

    seats.forEach(seat => {
        positions.push({
            id: seat.getAttribute('data-id'),
            x: parseInt(seat.style.left, 10) || 0,
            y: parseInt(seat.style.top, 10) || 0
        });
    });

    document.getElementById('HiddenField_Positions').value = JSON.stringify(positions);
}