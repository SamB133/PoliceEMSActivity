// Resolve this resource's name for NUI callbacks
const RES = (typeof GetParentResourceName === 'function')
	? GetParentResourceName() : 'PoliceEMSActivity';

// POST a callback back to the Lua client
function post(name, data) {
	return fetch(`https://${RES}/${name}`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=UTF-8' },
		body: JSON.stringify(data || {})
	});
}

const wrap = document.getElementById('wrap');
const list = document.getElementById('list');
const title = document.getElementById('title');

// Show the menu with the given title + department options
function openMenu(menuTitle, options) {
	title.textContent = menuTitle || 'Select Department';
	list.innerHTML = '';
	(options || []).forEach(opt => {
		const b = document.createElement('button');
		b.className = 'btn';
		b.textContent = opt.label;
		b.addEventListener('click', () => {
			closeMenu();
			post('selectDuty', { tag: opt.tag }); // Send the chosen identity back
		});
		list.appendChild(b);
	});
	wrap.classList.remove('hidden');
}

function closeMenu() {
	wrap.classList.add('hidden');
}

// Cancel button closes the menu without going on duty
document.getElementById('cancel').addEventListener('click', () => {
	closeMenu();
	post('closeDuty', {});
});

// ESC closes the menu without going on duty
window.addEventListener('keyup', (e) => {
	if (e.key === 'Escape' && !wrap.classList.contains('hidden')) {
		closeMenu();
		post('closeDuty', {});
	}
});

// Messages from the Lua client
window.addEventListener('message', (ev) => {
	const d = ev.data || {};
	if (d.action === 'open') openMenu(d.title, d.options);
});
