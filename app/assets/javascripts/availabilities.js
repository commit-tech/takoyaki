function toggle(id) {
  var cb = getCheckbox(id);
  cb.checked = !cb.checked;
  updateCheckbox(id, true);
}

function updateCheckbox(id, set) {
  var cb = getCheckbox(id);
  var td = document.getElementById("cell_" + id);
  var marker = document.getElementById("vertical_" + id);
  if (set) {
    updateCellClassName(td, marker, cb.checked, "-pending")
    enableButton("update-button");
    enableButton("cancel-button");
    enableButton("clear-all-button");
  } else {
    updateCellClassName(td, marker, cb.checked, "")
  }
}

function updateCellClassName(cell, marker, checked, suffix) {
  cell.classList.remove("availability-no");
  cell.classList.remove("availability-no-pending");
  cell.classList.remove("availability-yes");
  cell.classList.remove("availability-yes-pending");
  cell.classList.add("availability-" + (checked ? "yes" : "no") + suffix);

  marker.classList.remove("vertical");
  marker.classList.remove("vertical-pending");
  marker.classList.add("vertical" + suffix);
}

function getCheckbox(id) {
  return document.querySelectorAll("input[type='checkbox'][value='" + id + "']")[0];
}

function disableButton(buttonName) {
  var button = document.getElementById(buttonName);
  button.classList.addClass = "disabled";
  button.disabled = true;
}

function enableButton(buttonName) {
  var button = document.getElementById(buttonName);
  button.classList.remove("disabled")
  button.disabled = false;
}
