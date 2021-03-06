class TodosController < ApplicationController

  private
  def get_user
    if session[:user_id] == nil
      if Todo.count() > 0
        if Todo.maximum("user_id")
          session[:user_id] = Todo.maximum("user_id").to_i + 1
        else
          session[:user_id] = 1
        end
      end
    end
  end

  public
  def index
    get_user
  end

  def all
    @todos = Todo.where(user_id: session[:user_id]).select(:id, :task, :completed)
    render json: @todos
  end

  def create
    @todo = Todo.new
      @todo.task = params[:task]
      @todo.completed = false
      @todo.user_id = session[:user_id]
    @todo.save
    render json: @todo.slice(:id, :task, :completed)
  end

  def update
    @todo = Todo.find(params[:id])
    if @todo.user_id == session[:user_id]
      @todo.completed = !@todo.completed
      @todo.save
      render json: @todo.slice(:id, :task, :completed)
    else
      render []
    end
  end

  def toggle
    @todos = Array.new
    Todo.find_each do |todo|
      if todo.user_id == session[:user_id]
        todo.completed = params[:completed]
        @todos.push(todo)
        todo.save
      end
    end
    render json: @todos.slice(:id, :task, :completed)
  end

  def delete
    if params[:id].to_i == -1
      @todos = Todo.where(user_id: session[:user_id], completed: true)
      @todos.destroy_all
      @todos = Todo.where(user_id: session[:user_id]).select(:id, :task, :completed)
      render json: @todos
    else
      @todo = Todo.find(params[:id], user_id: session[:user_id])
      @todo.destroy
      render json: @todo.slice(:id, :task, :completed)
    end
  end

  def qrcode
    content = Array.new
    @todos = Todo.where(user_id: session[:user_id])
    @todos.each do |todo|
      content.push :t => todo[:task], :c => todo[:completed]
    end
    data = {
      succeeded: content.size > 0,
      code: view_context.generate_qrcode_base64( content.to_json, 384 )
    }
    render json: data
  end
end
