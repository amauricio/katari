window.onload = function(){
   var elem = document.querySelector('.content');
  /*var infScroll = new InfiniteScroll( elem, {
    // options
    path: '.pagination__next',
    append: '.item',
    history: false,
  });*/


}


var opts = {
  
    centerZero:     false,
    paddingBottom:20,
    zeroLineColor:  "#f90",

}

function FilleGraph () {
    Graph.apply(this, arguments);
}

FilleGraph.prototype = Object.create(Graph.prototype);
FilleGraph.prototype.constructor = FilleGraph;

/**
 * Draw a filled graph
 */
FilleGraph.prototype.drawData = function () {
    if (this.options.showLine) {
        Graph.prototype.drawData.call(this);
    }
     function addColorStops(gradient) {
      var green = 'rgba(10, 165, 93, 0.5)';
      var red = 'rgba(225, 60, 73, 1)';
      var st = 1 / data.history.length;

      for(var t in data.history){
      color = green;
        if(data.history[t].polarity == 'negative'){
          color = red;
        }
          gradient.addColorStop(st*t, color);
      }
    }

     var self = this,
            i    = self.data.length - 2;

        var g = self.context.createLinearGradient(0, 10, 307, 10);
        addColorStops(g);

      self.context.strokeStyle = g;
      self.context.lineWidth = self.options.lineWidth;

      self.context.beginPath();
      self.context.moveTo.apply(self.context, self.getPointCoordinates(self.data.length - 1));

      for (; i >= 0; i--) {
          self.context.lineTo.apply(self.context, self.getPointCoordinates(i));
      }

      self.context.stroke();
}
