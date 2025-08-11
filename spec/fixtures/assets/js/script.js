// Legacy JavaScript
var sampleFunction = function() {
  console.log('This is sample.');
};
sampleFunction();

// Modern ES6+ JavaScript to test harmony mode
const modernFunction = () => {
  const message = `Hello ES6+`;
  return message;
};

class TestClass {
  constructor(value) {
    this.value = value;
  }
  
  getValue() {
    return this.value;
  }
}

const instance = new TestClass('test');
console.log(modernFunction());
console.log(instance.getValue());
