const hamburger=document.querySelector("toggle-btn");
const toggler=document.querySelector("#icon");
hamburger.addEventListener("click", function(){
document.querySelector("#sidebar").classList.toggle("expand");
toggler.classList.toggle("bx-chevrons-right bx-remove-padding");
toggler.classList.toggle("bx-chevrons-left bx-remove-padding");
})