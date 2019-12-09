data__fs = {page:1, region:'Lima'};
FIRST_TIME = true;
already__data = false;
if(localStorage.getItem('data__fs')){
  var js = JSON.parse(localStorage.getItem('data__fs'))
  data__fs = js;
  already__data=true;
}

var serialize = function(obj) {
  var str = [];
  for (var p in obj)
    if (obj.hasOwnProperty(p)) {
      str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
    }
  return str.join("&");
}
window.onload = function(){

  if(already__data){

    if('sentencias' in data__fs)
    $('#cbSentencias').val(data__fs['sentencias'])

    if('q' in data__fs)
    $('.instantSearch').val(data__fs['q'])
  }

  $('.select').select2();
  var url__main = $('.main').data('url');

  elem = document.querySelector('.main');
  msnry = new Masonry( elem, {
    columnWidth:10,
      itemSelector: '.item', // select none at first
      // nicer reveal transition
      visibleStyle: { transform: 'translateY(0)', opacity: 1 },
      hiddenStyle: { transform: 'translateY(100px)', opacity: 0 },
  });

  really__init();
  function really__init(){
      
    var captureURL = function(){
     data__fs['page'] = this.pageIndex;
     return url__main+'?'+serialize(data__fs);
   }
    
    f= new InfiniteScroll( elem, {
        // options
        history:false,
        path: captureURL,
        append: '.item',
        outlayer: msnry,
        prefill: true,
        status: '.page-load-status',
        scrollThreshold:600,
        onInit: function () {
        }
      });
    f.on('load', function(){
      console.log(this.loadCount);
    })
    return f;

  }

    var infScroll = new really__init();
    clean__with__loading();
    function clean__with__loading(){
       $('.main').html('<img width="50" src="/giphy.gif" />');
    }
    function set__value__data(name, value){
      data__fs[name] = value;
      localStorage.setItem('data__fs', JSON.stringify(data__fs));
    }  
    function reload_items(){
       infScroll.destroy();
       infScroll = new really__init();
       clean__with__loading();
       msnry.reloadItems();
       msnry.layout();
       infScroll.loadNextPage();
    }
   $('#cbSentencias').on('change', function(){
     set__value__data('sentencias', $(this).val())
     reload_items();
   });

   $('#cbEstudios').on('change', function(){
     set__value__data('estudios', $(this).val())
     reload_items();
   });
   
   $('#cbRegion').on('change', function(){
     set__value__data('region', $(this).val())
     reload_items();
   });
   $('#cbCargo').on('change', function(){
     set__value__data('cargo', $(this).val())
     reload_items();
   });
    var delayTimer;
    function doSearch(text) {
        clearTimeout(delayTimer);
        delayTimer = setTimeout(function() {
            data__fs['q']  = text;
           reload_items();
        }, 1000); 
    }

   $('.instantSearch').on('input', function(){
      set__value__data('q', $(this).val())
      clean__with__loading();
      doSearch($(this).val().trim())
   });

   

}
