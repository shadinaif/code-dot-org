import {assert} from 'chai';
import {combineReducers} from 'redux';
import reducers, {
  reorderLevel,
  moveLevelToLesson,
  addGroup,
  addLesson,
  moveLesson,
  setActiveVariant,
  setField,
  setLessonGroup
} from '@cdo/apps/lib/script-editor/editorRedux';

const getInitialState = () => ({
  levelKeyList: {},
  lessons: [
    {
      id: 100,
      name: 'A',
      levels: [
        {
          ids: [1],
          activeId: 1
        },
        {
          ids: [4],
          activeId: 4
        },
        {
          ids: [5],
          activeId: 5
        },
        {
          ids: [6],
          activeId: 6
        }
      ]
    },
    {
      name: 'B',
      id: 101,
      levels: [
        {
          ids: [2, 3],
          activeId: 3
        }
      ]
    }
  ]
});

const reducer = combineReducers(reducers);

describe('editorRedux reducer tests', () => {
  let initialState;
  beforeEach(() => (initialState = getInitialState()));

  it('reorder levels', () => {
    const nextState = reducer(initialState, reorderLevel(1, 3, 1)).lessons;
    assert.deepEqual(nextState[0].levels.map(l => l.activeId), [5, 1, 4, 6]);
  });

  it('moves level to lesson', () => {
    const nextState = reducer(initialState, moveLevelToLesson(1, 3, 2)).lessons;
    assert.deepEqual(nextState[0].levels.map(l => l.activeId), [1, 4, 6]);
    assert.deepEqual(nextState[1].levels.map(l => l.activeId), [3, 5]);
  });

  it('add group', () => {
    const nextState = reducer(
      initialState,
      addGroup('New Lesson 1', 'New Group')
    ).lessons;
    assert.equal(nextState[nextState.length - 1].name, 'New Lesson 1');
  });

  it('add lesson', () => {
    const nextState = reducer(initialState, addLesson(1, 'New Lesson 2'))
      .lessons;
    assert.deepEqual(nextState.map(s => s.name), ['A', 'New Lesson 2', 'B']);
  });

  it('set active variant', () => {
    const nextState = reducer(initialState, setActiveVariant(2, 1, 2)).lessons;
    assert.equal(nextState[1].levels[0].activeId, 2);
  });

  it('set level field', () => {
    let nextState = reducer(initialState, setField(1, 1, {videoKey: '_a_'}));
    assert.equal(nextState.lessons[0].levels[0].videoKey, '_a_');
    nextState = reducer(nextState, setField(1, 1, {skin: '_b_'}));
    assert.equal(nextState.lessons[0].levels[0].skin, '_b_');
    nextState = reducer(nextState, setField(1, 1, {conceptDifficulty: '_c_'}));
    assert.equal(nextState.lessons[0].levels[0].conceptDifficulty, '_c_');
    nextState = reducer(nextState, setField(1, 1, {concepts: '_d_'}));
    assert.equal(nextState.lessons[0].levels[0].concepts, '_d_');
  });

  describe('lesson groups', () => {
    let initialLessons = [];

    beforeEach(() => {
      initialLessons = [
        {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
        {lesson_group: 'X', id: 102, position: 2, relativePosition: 2},
        {lesson_group: 'Y', id: 103, position: 3, relativePosition: 3},
        {lesson_group: 'Y', id: 104, position: 4, relativePosition: 4}
      ];
      initialState.lessons = initialLessons;
    });

    it('moves a lesson up three times', () => {
      const id = 104;
      let position = initialState.lessons.find(s => s.id === id).position;
      let state = reducer(initialState, moveLesson(position, 'up'));
      assert.deepEqual(
        [
          {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
          {lesson_group: 'X', id: 102, position: 2, relativePosition: 2},
          {lesson_group: 'Y', id: 104, position: 3, relativePosition: 3},
          {lesson_group: 'Y', id: 103, position: 4, relativePosition: 4}
        ],
        state.lessons,
        'first move changes position but not group'
      );

      position = state.lessons.find(s => s.id === id).position;
      state = reducer(state, moveLesson(position, 'up'));
      assert.deepEqual(
        [
          {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
          {lesson_group: 'X', id: 102, position: 2, relativePosition: 2},
          {lesson_group: 'X', id: 104, position: 3, relativePosition: 3},
          {lesson_group: 'Y', id: 103, position: 4, relativePosition: 4}
        ],
        state.lessons,
        'second move changes group but not position'
      );

      position = state.lessons.find(s => s.id === id).position;
      state = reducer(state, moveLesson(position, 'up'));
      assert.deepEqual(
        [
          {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
          {lesson_group: 'X', id: 104, position: 2, relativePosition: 2},
          {lesson_group: 'X', id: 102, position: 3, relativePosition: 3},
          {lesson_group: 'Y', id: 103, position: 4, relativePosition: 4}
        ],
        state.lessons,
        'third move changes group but not position'
      );
    });

    describe('set lesson group', () => {
      it('moves unique lesson group to the end of the script', () => {
        let state = reducer(initialState, setLessonGroup(2, 'Z'));
        assert.deepEqual(
          [
            {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
            {lesson_group: 'Y', id: 103, position: 2, relativePosition: 2},
            {lesson_group: 'Y', id: 104, position: 3, relativePosition: 3},
            {lesson_group: 'Z', id: 102, position: 4, relativePosition: 4}
          ],
          state.lessons
        );
      });

      it('groups with others in same lesson group', () => {
        const newState = reducer(initialState, setLessonGroup(4, 'X'));
        assert.deepEqual(
          [
            {lesson_group: 'X', id: 101, position: 1, relativePosition: 1},
            {lesson_group: 'X', id: 102, position: 2, relativePosition: 2},
            {lesson_group: 'X', id: 104, position: 3, relativePosition: 3},
            {lesson_group: 'Y', id: 103, position: 4, relativePosition: 4}
          ],
          newState.lessons
        );
      });
    });
  });
});
