/* scroll to top when menu button is clicked */
document.addEventListener('click',function(e){
    if(e.target == document.querySelector('#tab-sharing .action-item__menutoggle')){
        console.debug('[Debug] cssjsloader : click menu button')
        window.scrollTo(0,0);
    }
});