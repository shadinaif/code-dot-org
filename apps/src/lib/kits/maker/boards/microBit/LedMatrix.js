export default class LedMatrix {
  constructor(board) {
    this.board = board;
    this.matrix = [
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0]
    ];
  }

  display(pixelArray) {
    this.board.mb.displayShow(/* useGrayscale */ false, pixelArray);
  }

  scrollString(value) {
    this.board.mb.scrollString(value);
  }

  scrollNumber(value) {
    this.board.mb.scrollInteger(value);
  }

  on(x, y, brightness) {
    this.board.mb.displayPlot(x, y, brightness);
    this.matrix[x][y] = 1;
  }

  off(x, y) {
    this.board.mb.displayPlot(x, y, 0);
    this.matrix[x][y] = 0;
  }

  toggle(x, y, brightness) {
    this.matrix[x][y] > 0 ? this.off(x, y) : this.on(x, y, brightness);
  }

  clear() {
    this.board.mb.displayClear();
  }
}
