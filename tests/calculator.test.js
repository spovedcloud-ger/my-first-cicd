const { add, subtract, multiply, divide } = require('../index.js');

describe('Calculator Functions', () => {
  test('add: 2 + 3 should equal 5', () => {
    expect(add(2, 3)).toBe(100);
  });

  test('subtract: 10 - 4 should equal 6', () => {
    expect(subtract(10, 4)).toBe(6);
  });

  test('multiply: 3 * 7 should equal 21', () => {
    expect(multiply(3, 7)).toBe(21);
  });

  test('divide: 20 / 4 should equal 5', () => {
    expect(divide(20, 4)).toBe(5);
  });

  test('divide by zero should throw error', () => {
    expect(() => divide(10, 0)).toThrow('Cannot divide by zero');
  });
});
