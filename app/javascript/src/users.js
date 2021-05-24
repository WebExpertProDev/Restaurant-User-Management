import React from "react";
import {
  List,
  Edit,
  SimpleForm,
  TextInput,
  Datagrid,
  DateField,
  NumberField,
  BooleanField,
  TextField,
  EmailField,
} from "react-admin";

export const UsersList = (props) => (
  <List {...props}>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <TextField source="name" />
      <NumberField source="number" label="Phone Number" />
      <EmailField source="email" />
      <DateField source="created_at" label="Signup Date" />
      <BooleanField source="has_yelp_creds" />
      <BooleanField source="has_opentable_creds" />
      <BooleanField source="has_resy_creds" />
      <BooleanField source="has_tock_creds" />
    </Datagrid>
  </List>
);

export const UsersEdit = (props) => (
  <Edit {...props}>
    <SimpleForm>
      <TextInput disabled source="id" />
      <TextInput source="name" />
      <TextInput source="number" label="Phone Number" />
      <TextInput source="email" label="Email" />
    </SimpleForm>
  </Edit>
);

export default UsersList;
