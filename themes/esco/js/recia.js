(function(){
        //pour supprimer la possibilité de modifier ses info personnelles. 
        let inputNodeList = document.querySelectorAll('div#personal-settings input');
        if (inputNodeList) {
                inputNodeList.forEach(function(input) {input.readOnly = true});
        }
})();
